FROM ros:humble-ros-base

ENV ROS_DISTRO=humble
ENV ROS_ROOT=/opt/ros/${ROS_DISTRO}

#download and build 
ENV ROS_WS /opt/ros_ws

USER $USERNAME
