#!/bin/bash
# Run FAST-LIO on a ROS2 bag and save odometry in TUM format
# Usage: ./run_fast_lio.sh <bag_path> <output_dir>
set -e

BAG_PATH="${1:?Usage: $0 <bag_path> <output_dir>}"
OUTPUT_DIR="${2:?Usage: $0 <bag_path> <output_dir>}"

mkdir -p "$OUTPUT_DIR"
source /opt/ros/humble/setup.bash
source /ros2_ws/install/setup.bash

TUM_FILE="$OUTPUT_DIR/fast_lio_trajectory.tum"
ODOM_TOPIC="/Odometry"

echo "[FAST-LIO] Starting FAST-LIO node..."

# Launch FAST-LIO with Ouster 64-beam config
ros2 launch fast_lio mapping.launch.py \
    config_file:=ouster64.yaml &
FASTLIO_PID=$!

sleep 5

echo "[FAST-LIO] Recording odometry to TUM format..."

# Record odometry messages to a temp bag
TEMP_BAG="$OUTPUT_DIR/temp_odom_bag"
ros2 bag record -o "$TEMP_BAG" "$ODOM_TOPIC" &
RECORD_PID=$!

echo "[FAST-LIO] Playing input bag..."
ros2 bag play "$BAG_PATH" \
    --remap /os1_cloud_node/points:=/livox/lidar \
    --remap /os1_cloud_node/imu:=/livox/imu \
    --clock

echo "[FAST-LIO] Bag playback complete. Waiting for processing..."
sleep 10

# Stop recording and FAST-LIO
kill $RECORD_PID 2>/dev/null || true
kill $FASTLIO_PID 2>/dev/null || true
wait $RECORD_PID 2>/dev/null || true
wait $FASTLIO_PID 2>/dev/null || true

echo "[FAST-LIO] Converting odometry to TUM format..."

python3 -c "
import sqlite3, os
from rosbags.rosbag2 import Reader
from rosbags.serde import deserialize_cdr

tum_lines = []
with Reader('${TEMP_BAG}') as reader:
    for connection, timestamp, rawdata in reader.messages():
        if connection.topic == '${ODOM_TOPIC}':
            msg = deserialize_cdr(rawdata, connection.msgtype)
            t = msg.header.stamp.sec + msg.header.stamp.nanosec * 1e-9
            p = msg.pose.pose.position
            q = msg.pose.pose.orientation
            tum_lines.append(f'{t:.9f} {p.x} {p.y} {p.z} {q.x} {q.y} {q.z} {q.w}')

with open('${TUM_FILE}', 'w') as f:
    f.write('\n'.join(tum_lines) + '\n')
print(f'[FAST-LIO] Saved {len(tum_lines)} poses to ${TUM_FILE}')
"

# Cleanup temp bag
rm -rf "$TEMP_BAG"

echo "[FAST-LIO] Done. Output: $TUM_FILE"
