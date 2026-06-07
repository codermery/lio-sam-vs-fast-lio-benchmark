FROM osrf/ros:humble-desktop-full

ENV DEBIAN_FRONTEND=noninteractive
ENV ROS_DISTRO=humble

# System dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    git \
    python3-pip \
    libpcl-dev \
    libeigen3-dev \
    libomp-dev \
    software-properties-common \
    ros-humble-perception-pcl \
    ros-humble-pcl-msgs \
    ros-humble-vision-opencv \
    ros-humble-xacro \
    ros-humble-rviz2 \
    && rm -rf /var/lib/apt/lists/*

# GTSAM 4.1 from PPA (required by LIO-SAM)
RUN add-apt-repository ppa:borglab/gtsam-release-4.1 -y \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
       libgtsam-dev \
       libgtsam-unstable-dev \
    && rm -rf /var/lib/apt/lists/*

# Python evaluation tools
RUN pip3 install --no-cache-dir \
    evo \
    matplotlib \
    pandas \
    numpy \
    rosbags

# Livox SDK2 (required by livox_ros_driver2 which FAST-LIO depends on)
RUN cd /tmp \
    && git clone https://github.com/Livox-SDK/Livox-SDK2.git \
    && cd Livox-SDK2 && mkdir build && cd build \
    && cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local \
    && make -j$(nproc) && make install && ldconfig \
    && rm -rf /tmp/Livox-SDK2

# Workspace setup
RUN mkdir -p /ros2_ws/src /ros2_ws/data /ros2_ws/results
WORKDIR /ros2_ws

# Shell configuration
RUN echo "source /opt/ros/${ROS_DISTRO}/setup.bash" >> /root/.bashrc \
    && echo '[ -f /ros2_ws/install/setup.bash ] && source /ros2_ws/install/setup.bash' >> /root/.bashrc

COPY setup_workspace.sh /ros2_ws/setup_workspace.sh
RUN chmod +x /ros2_ws/setup_workspace.sh

CMD ["/bin/bash"]
