#!/bin/bash
# Full benchmark pipeline: download → convert → run both algorithms → evaluate
# Run this from the project root directory.
set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
DATA_DIR="$PROJECT_DIR/data/newer_college/01_short_experiment"
RESULTS_DIR="$PROJECT_DIR/results"
BAG_PATH="$DATA_DIR/ros2_bags/rooster_2020-03-10-10-36-30_0"
CONTAINER_NAME="lio-benchmark"
IMAGE_NAME="lio-benchmark"

echo "============================================================"
echo " LIO-SAM vs FAST-LIO — Full Benchmark Pipeline"
echo "============================================================"
echo ""

# Step 1: Download dataset (runs on host)
if [ ! -d "$DATA_DIR/rosbag" ] || [ -z "$(ls $DATA_DIR/rosbag/*.bag 2>/dev/null)" ]; then
    echo "[Step 1/6] Downloading dataset..."
    bash "$PROJECT_DIR/scripts/download_newer_college.sh" "$DATA_DIR"
else
    echo "[Step 1/6] Dataset already downloaded. Skipping."
fi

# Step 2: Convert bags (runs on host)
if [ ! -d "$DATA_DIR/ros2_bags" ] || [ -z "$(ls -d $DATA_DIR/ros2_bags/rooster_* 2>/dev/null)" ]; then
    echo "[Step 2/6] Converting ROS1 bags to ROS2..."
    bash "$PROJECT_DIR/scripts/convert_bags.sh" "$DATA_DIR"
else
    echo "[Step 2/6] Bags already converted. Skipping."
fi

# Step 3: Convert ground truth
if [ ! -f "$RESULTS_DIR/ground_truth.tum" ]; then
    echo "[Step 3/6] Converting ground truth to TUM format..."
    mkdir -p "$RESULTS_DIR"
    python3 "$PROJECT_DIR/scripts/csv_to_tum.py" \
        "$DATA_DIR/ground_truth/registered_poses.csv" \
        "$RESULTS_DIR/ground_truth.tum"
else
    echo "[Step 3/6] Ground truth already converted. Skipping."
fi

# Step 4: Build Docker image if needed
if ! docker image inspect "$IMAGE_NAME" &>/dev/null; then
    echo "[Step 4/6] Building Docker image..."
    docker build -t "$IMAGE_NAME" "$PROJECT_DIR"
else
    echo "[Step 4/6] Docker image exists. Skipping build."
fi

echo ""
echo "[Step 5/6] Running LIO-SAM and FAST-LIO inside Docker..."
echo "           This takes ~7 minutes (2x bag duration + processing)."
echo ""

# Remove old container if exists
docker rm -f "$CONTAINER_NAME" 2>/dev/null || true

# Run both algorithms
docker run --rm --network host \
    --name "$CONTAINER_NAME" \
    -v "$PROJECT_DIR:/ros2_ws/host" \
    -v "$DATA_DIR:/ros2_ws/data" \
    -v "$RESULTS_DIR:/ros2_ws/results" \
    "$IMAGE_NAME" /ros2_ws/ros_entrypoint.sh bash -c "
        # Build workspace if not built
        if [ ! -f /ros2_ws/install/setup.bash ]; then
            /ros2_ws/setup_workspace.sh
        fi
        source /ros2_ws/install/setup.bash

        echo '--- Running LIO-SAM ---'
        bash /ros2_ws/host/scripts/run_lio_sam.sh \
            --bag /ros2_ws/data/ros2_bags/rooster_2020-03-10-10-36-30_0 \
            --output /ros2_ws/results

        echo ''
        echo '--- Running FAST-LIO ---'
        bash /ros2_ws/host/scripts/run_fast_lio.sh \
            --bag /ros2_ws/data/ros2_bags/rooster_2020-03-10-10-36-30_0 \
            --output /ros2_ws/results
    "

# Step 6: Evaluate (can run on host if evo is installed, or in Docker)
echo ""
echo "[Step 6/6] Running evaluation..."
docker run --rm \
    -v "$PROJECT_DIR:/ros2_ws/host" \
    -v "$RESULTS_DIR:/ros2_ws/results" \
    "$IMAGE_NAME" /ros2_ws/ros_entrypoint.sh python3 /ros2_ws/host/scripts/evaluate.py \
        --gt /ros2_ws/results/ground_truth.tum \
        --lio-sam /ros2_ws/results/lio_sam_trajectory.tum \
        --fast-lio /ros2_ws/results/fast_lio_trajectory.tum \
        --output-dir /ros2_ws/results/

echo ""
echo "============================================================"
echo " Benchmark complete!"
echo " Results: $RESULTS_DIR/"
echo "   - trajectory_xy.png"
echo "   - ate_comparison.png"
echo "   - metrics_table.md"
echo "============================================================"
