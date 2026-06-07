#!/bin/bash
# Convert ROS1 bags to ROS2 format using rosbags-convert
# Idempotent: skips bags that have already been converted.
set -e

DATA_DIR="${1:-./data/newer_college/01_short_experiment}"
ROSBAG_DIR="$DATA_DIR/rosbag"
OUTPUT_DIR="$DATA_DIR/ros2_bags"
KEEP_ORIGINALS=true

# Parse flags
for arg in "$@"; do
    case $arg in
        --delete-originals) KEEP_ORIGINALS=false ;;
    esac
done

# Check dependencies
if ! command -v rosbags-convert &> /dev/null; then
    echo "[*] Installing rosbags..."
    pip install rosbags
fi

# Find bag files (handle nested rosbag/rosbag/ from gdown quirk)
BAG_SOURCE="$ROSBAG_DIR"
if [ -d "$ROSBAG_DIR/rosbag" ]; then
    BAG_SOURCE="$ROSBAG_DIR/rosbag"
fi

BAG_FILES=$(find "$BAG_SOURCE" -name "*.bag" -type f | sort)
if [ -z "$BAG_FILES" ]; then
    echo "ERROR: No .bag files found in $BAG_SOURCE"
    exit 1
fi

BAG_COUNT=$(echo "$BAG_FILES" | wc -l)
echo "============================================================"
echo " ROS1 → ROS2 Bag Conversion"
echo " Source: $BAG_SOURCE ($BAG_COUNT bags)"
echo " Output: $OUTPUT_DIR"
echo " Keep originals: $KEEP_ORIGINALS"
echo "============================================================"

mkdir -p "$OUTPUT_DIR"

CONVERTED=0
SKIPPED=0

for bag in $BAG_FILES; do
    name=$(basename "$bag" .bag)
    output_path="$OUTPUT_DIR/$name"

    if [ -d "$output_path" ] && [ -f "$output_path/metadata.yaml" ]; then
        echo "  [SKIP] $name (already converted)"
        SKIPPED=$((SKIPPED + 1))
        continue
    fi

    echo "  [CONVERT] $name..."
    rosbags-convert --src "$bag" --dst "$output_path"
    CONVERTED=$((CONVERTED + 1))
done

echo ""
echo "Done: $CONVERTED converted, $SKIPPED skipped."

if [ "$KEEP_ORIGINALS" = false ]; then
    echo "Deleting original ROS1 bags..."
    rm -f $BAG_FILES
    echo "Freed disk space."
fi

echo ""
echo "Next step: Run the benchmark inside Docker."
echo "============================================================"
