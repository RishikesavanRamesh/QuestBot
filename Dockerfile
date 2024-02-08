FROM ros:humble-ros-base

ENV ROS_DISTRO=humble
ENV ROS_ROOT=/opt/ros/${ROS_DISTRO}
ENV ROS_WS /opt/ros_ws

# Download and build questbot

# 1) Copy installaion scripts
COPY questbot/install/robot.install robot.install
# 2) Initialize the workspace and install required pkg & dependencies
RUN mkdir -p $ROS_WS/src && \
    vcs import $ROS_WS/ < robot.install && \
    apt-get update && apt-get install -y \
    $(cat $ROS_WS/src/questbot/install/robot_tools.install) \           
    $(cat $ROS_WS/src/questbot/install/dev_tools.install) && \
    rosdep install --from-paths $ROS_WS/src --ignore-src -r -y && \
    rm -rf /var/lib/apt/lists/*

#changing workingdir
WORKDIR $ROS_WS
#stop all processes aka Ctr + C
STOPSIGNAL SIGINT