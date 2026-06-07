#!/bin/bash
# Run LIO-SAM on a ROS2 bag and save odometry in TUM format
# Usage: ./run_lio_sam.sh <bag_path> <output_dir>
set -e

BAG_PATH="${1:?Usage: $0 <bag_path> <output_dir>}"
OUTPUT_DIR="${2:?Usage: $0 <bag_path> <output_dir>}"

mkdir -p "$OUTPUT_DIR"
source /opt/ros/humble/setup.bash
source /ros2_ws/install/setup.bash

TUM_FILE="$OUTPUT_DIR/lio_sam_trajectory.tum"
ODOM_TOPIC="/lio_sam/mapping/odometry"

echo "[LIO-SAM] Starting LIO-SAM node..."

# Launch LIO-SAM with Ouster config remapping
ros2 launch lio_sam run.launch.py \
    params_file:=/ros2_ws/src/LIO-SAM/config/params.yaml &
LIOSAM_PID=$!

sleep 5

echo "[LIO-SAM] Recording odometry to TUM format..."

# Record odometry messages to a temp bag
TEMP_BAG="$OUTPUT_DIR/temp_odom_bag"
ros2 bag record -o "$TEMP_BAG" "$ODOM_TOPIC" &
RECORD_PID=$!

echo "[LIO-SAM] Playing input bag..."
ros2 bag play "$BAG_PATH" \
    --remap /os1_cloud_node/points:=/points_raw \
    --remap /os1_cloud_node/imu:=/imu_raw \
    --clock

echo "[LIO-SAM] Bag playback complete. Waiting for processing..."
sleep 10

# Stop recording and LIO-SAM
kill $RECORD_PID 2>/dev/null || true
kill $LIOSAM_PID 2>/dev/null || true
wait $RECORD_PID 2>/dev/null || true
wait $LIOSAM_PID 2>/dev/null || true

echo "[LIO-SAM] Converting odometry to TUM format..."

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
print(f'[LIO-SAM] Saved {len(tum_lines)} poses to ${TUM_FILE}')
"

# Cleanup temp bag
rm -rf "$TEMP_BAG"

echo "[LIO-SAM] Done. Output: $TUM_FILE"
