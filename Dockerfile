FROM ros:humble-ros-base

ENV ROS_DISTRO=humble
ENV ROS_ROOT=/opt/ros/${ROS_DISTRO}

# Download and build questbot
ENV ROS_WS /opt/ros_ws
# Copy installaion scripts
COPY questbot/install/robot.install robot.install
# Initialize the workspace and install python dependencies
RUN mkdir -p $ROS_WS/src && \
    vcs import $ROS_WS/ < robot.install && \
    apt-get update && \
    apt-get install python3-pip && \
    apt-get install $(cat $ROS_WS/src/questbot/install/dev_apt_pkg.install)

USER $USERNAME