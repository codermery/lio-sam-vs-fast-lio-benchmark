#!/bin/bash
set -e

echo "=== Setting up LIO-SAM vs FAST-LIO workspace ==="

cd /ros2_ws/src

# LIO-SAM (ROS2 branch)
if [ ! -d "LIO-SAM" ]; then
    echo "[1/3] Cloning LIO-SAM (ros2 branch)..."
    git clone -b ros2 https://github.com/TixiaoShan/LIO-SAM.git
fi

# FAST-LIO (ROS2 port by Ericsii, recursive for ikd-Tree)
if [ ! -d "FAST_LIO" ]; then
    echo "[2/3] Cloning FAST-LIO (ros2 branch, recursive)..."
    git clone -b ros2 --recursive https://github.com/Ericsii/FAST_LIO.git
fi

# Livox ROS driver (dependency for FAST-LIO with Livox sensors)
# This repo uses package_ROS2.xml instead of package.xml — must rename for colcon
if [ ! -d "livox_ros_driver2" ]; then
    echo "[3/3] Cloning livox_ros_driver2..."
    git clone https://github.com/Livox-SDK/livox_ros_driver2.git
    cd livox_ros_driver2
    cp -f package_ROS2.xml package.xml
    cp -rf launch_ROS2/ launch/
    cd ..
fi

# Install Livox SDK2 (required by livox_ros_driver2)
if [ ! -f /usr/local/lib/liblivox_lidar_sdk_shared.so ]; then
    echo "[+] Installing Livox SDK2..."
    cd /tmp
    git clone https://github.com/Livox-SDK/Livox-SDK2.git
    cd Livox-SDK2 && mkdir build && cd build
    cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local
    make -j$(nproc) && make install && ldconfig
    rm -rf /tmp/Livox-SDK2
fi

cd /ros2_ws

echo "=== Building workspace (this will take 10-20 minutes) ==="
source /opt/ros/humble/setup.bash

colcon build --symlink-install \
    --parallel-workers $(nproc) \
    --cmake-args -DCMAKE_BUILD_TYPE=Release -DROS_EDITION=ROS2 -DDISTRO_ROS=humble

echo "=== Workspace build complete ==="
echo "Source with: source /ros2_ws/install/setup.bash"
