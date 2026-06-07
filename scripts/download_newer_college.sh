#!/bin/bash
# Download Newer College Dataset - 01_short_experiment sequence
# Uses gdown to download from Google Drive
#
# WARNING: This downloads ~44 GB of ROS1 bag files.
# Make sure you have sufficient disk space and bandwidth.
set -e

DATA_DIR="${1:-./data/newer_college/01_short_experiment}"

echo "============================================================"
echo " Newer College Dataset Downloader"
echo " Sequence: 01_short_experiment (Ouster OS-1 64-beam)"
echo " Target:   $DATA_DIR"
echo "============================================================"
echo ""
echo "WARNING: This will download ~44 GB of data."
echo "Press Ctrl+C within 5 seconds to cancel."
sleep 5

# Check dependencies
if ! command -v gdown &> /dev/null; then
    echo "[*] Installing gdown..."
    pip install gdown
fi

mkdir -p "$DATA_DIR"/{rosbag,ground_truth,time_offsets}

# Download rosbag folder (10 split bags, ~11 GB each)
echo ""
echo "[1/3] Downloading rosbag files (~44 GB)..."
echo "      Google Drive may rate-limit after 4-5 files."
echo "      If download fails, re-run this script — it will resume."
gdown --folder "https://drive.google.com/drive/folders/1WWtyU6bv4-JKwe-XuSeKEEEBhbgoFHRG" \
    -O "$DATA_DIR/rosbag/"

# Download ground truth
echo ""
echo "[2/3] Downloading ground truth (registered_poses.csv)..."
gdown "11VWvHxjitd4ijARD4dJ3WjFuZ_QbInVy" \
    -O "$DATA_DIR/ground_truth/registered_poses.csv"

# Download time offsets
echo ""
echo "[3/3] Downloading time offsets..."
gdown "1ZAddzVTZLWafq99ElmmDvz0Av4IUZlFO" \
    -O "$DATA_DIR/time_offsets/time_offsets.csv"

echo ""
echo "============================================================"
echo " Download complete!"
echo " Files:"
ls -lah "$DATA_DIR/rosbag/"*.bag 2>/dev/null || echo "  (no .bag files — check rosbag/ subfolder)"
ls -lah "$DATA_DIR/ground_truth/"
echo ""
echo " Next step: bash scripts/convert_bags.sh"
echo "============================================================"
