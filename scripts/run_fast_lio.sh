#!/bin/bash
# Run FAST-LIO on a ROS2 bag and save odometry in TUM format
# Usage: ./run_fast_lio.sh --bag <path> [--output <dir>] [--config <yaml>]
set -e

source /opt/ros/humble/setup.bash
[ -f /ros2_ws/install/setup.bash ] && source /ros2_ws/install/setup.bash

BAG_PATH=""
OUTPUT_DIR="/ros2_ws/results"
CONFIG_FILE="ouster64.yaml"

while [[ $# -gt 0 ]]; do
    case $1 in
        --bag) BAG_PATH="$2"; shift 2 ;;
        --output) OUTPUT_DIR="$2"; shift 2 ;;
        --config) CONFIG_FILE="$2"; shift 2 ;;
        *) echo "Unknown arg: $1"; exit 1 ;;
    esac
done

if [ -z "$BAG_PATH" ]; then
    echo "Usage: $0 --bag <ros2_bag_path> [--output <dir>] [--config <yaml>]"
    exit 1
fi

mkdir -p "$OUTPUT_DIR"
ODOM_TOPIC="/Odometry"
TUM_FILE="$OUTPUT_DIR/fast_lio_trajectory.tum"
TEMP_BAG="/tmp/fast_lio_odom_bag"
rm -rf "$TEMP_BAG"

echo "[FAST-LIO] Config: $CONFIG_FILE"
echo "[FAST-LIO] Bag:    $BAG_PATH"
echo "[FAST-LIO] Output: $TUM_FILE"

# Launch FAST-LIO
unset DISPLAY
ros2 launch fast_lio mapping.launch.py config_file:="$CONFIG_FILE" &
FASTLIO_PID=$!
sleep 10

# Record odometry
ros2 bag record -o "$TEMP_BAG" "$ODOM_TOPIC" &
RECORD_PID=$!
sleep 2

# Play bag
echo "[FAST-LIO] Playing bag..."
START_TIME=$(date +%s)
ros2 bag play "$BAG_PATH" --rate 1.0 --clock
echo "[FAST-LIO] Playback done. Waiting for processing..."
sleep 15

# Stop recording and FAST-LIO
kill $RECORD_PID 2>/dev/null; wait $RECORD_PID 2>/dev/null || true
kill $FASTLIO_PID 2>/dev/null; wait $FASTLIO_PID 2>/dev/null || true

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))

# Convert to TUM
echo "[FAST-LIO] Converting to TUM format..."
python3 -c "
from rosbags.rosbag2 import Reader
from rosbags.typesys import Stores, get_typestore
typestore = get_typestore(Stores.ROS2_HUMBLE)
poses = []
with Reader('$TEMP_BAG') as reader:
    for conn, timestamp, rawdata in reader.messages():
        if conn.topic == '$ODOM_TOPIC':
            msg = typestore.deserialize_cdr(rawdata, conn.msgtype)
            t = msg.header.stamp.sec + msg.header.stamp.nanosec * 1e-9
            p = msg.pose.pose.position
            q = msg.pose.pose.orientation
            poses.append(f'{t:.9f} {p.x} {p.y} {p.z} {q.x} {q.y} {q.z} {q.w}')
with open('$TUM_FILE', 'w') as f:
    f.write('\n'.join(poses) + '\n')
print(f'[FAST-LIO] Saved {len(poses)} poses to $TUM_FILE')
print(f'[FAST-LIO] Runtime: ${ELAPSED}s')
"

rm -rf "$TEMP_BAG"
