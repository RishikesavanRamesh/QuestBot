

ARG ROS_DISTRO=humble
ARG BOT_NAME=questbot
ARG DEVELOPMENT_USERNAME=ros






###########################################
# Base image
###########################################
#FROM ubuntu:22.04 AS base
FROM kasmweb/ubuntu-jammy-dind:1.15.0 AS base



ARG ROS_DISTRO






ENV DEBIAN_FRONTEND=noninteractive

# Install language
RUN apt-get update && apt-get install -y \
  locales \
  && locale-gen en_US.UTF-8 \
  && update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 \
  && rm -rf /var/lib/apt/lists/*
ENV LANG en_US.UTF-8

# Install timezone
RUN ln -fs /usr/share/zoneinfo/UTC /etc/localtime \
  && export DEBIAN_FRONTEND=noninteractive \
  && apt-get update \
  && apt-get install -y tzdata \
  && dpkg-reconfigure --frontend noninteractive tzdata \
  && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get -y upgrade \
    && rm -rf /var/lib/apt/lists/*

# Install common programs
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    gnupg2 \
    lsb-release \
    sudo \
    software-properties-common \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Install ROS2
RUN sudo add-apt-repository universe \
  && curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null \
  && apt-get update && apt-get install -y --no-install-recommends \
    ros-${ROS_DISTRO}-ros-base \
    python3-argcomplete \
  && rm -rf /var/lib/apt/lists/*

ENV ROS_DISTRO=${ROS_DISTRO}
ENV AMENT_PREFIX_PATH=/opt/ros/${ROS_DISTRO}
ENV COLCON_PREFIX_PATH=/opt/ros/${ROS_DISTRO}
ENV LD_LIBRARY_PATH=/opt/ros/${ROS_DISTRO}/lib
ENV PATH=/opt/ros/${ROS_DISTRO}/bin:$PATH
ENV PYTHONPATH=/opt/ros/${ROS_DISTRO}/lib/python3.10/site-packages
ENV ROS_PYTHON_VERSION=3
ENV ROS_VERSION=2
ENV DEBIAN_FRONTEND=



###########################################
#  Overlay image
###########################################
FROM base AS overlay





ARG ROS_DISTRO
ARG BOT_NAME


ENV ROS_DISTRO=${ROS_DISTRO}
SHELL ["/bin/bash", "-c"]

# Create Colcon workspace with external dependencies
RUN mkdir -p /${BOT_NAME}/src
WORKDIR /${BOT_NAME}/src



 
# Use Cyclone DDS as middleware
RUN apt-get update && apt-get install -y --no-install-recommends \
 ros-${ROS_DISTRO}-rmw-cyclonedds-cpp
ENV RMW_IMPLEMENTATION=rmw_cyclonedds_cpp

# Build the base Colcon workspace, installing dependencies first.
WORKDIR /${BOT_NAME}
RUN source /opt/ros/${ROS_DISTRO}/setup.bash \
 && apt-get update -y \
 && apt-get install -y python3-rosdep \
 && rosdep init && rosdep update \
 && apt install -y python3-colcon-common-extensions \
 && rosdep install --from-paths src --ignore-src --rosdistro ${ROS_DISTRO} -y \
 && colcon build --symlink-install









###########################################
#  Developer image
###########################################
FROM overlay AS dev



ARG ROS_DISTRO
ARG DEVELOPMENT_USERNAME
ARG USER_UID=1000
ARG USER_GID=$USER_UID


ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
  bash-completion \
  build-essential \
  cmake \
  gdb \
  git \
  openssh-client \
  python3-argcomplete \
  python3-pip \
  ros-dev-tools \
  ros-${ROS_DISTRO}-ament-* \
  vim \
  && rm -rf /var/lib/apt/lists/*

RUN rosdep init || echo "rosdep already initialized"



# Create a non-root user
RUN groupadd --gid $USER_GID $DEVELOPMENT_USERNAME \
  && useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $DEVELOPMENT_USERNAME \
  # Add sudo support for the non-root user
  && apt-get update \
  && apt-get install -y sudo \
  && echo $DEVELOPMENT_USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$DEVELOPMENT_USERNAME\
  && chmod 0440 /etc/sudoers.d/$DEVELOPMENT_USERNAME \
  && rm -rf /var/lib/apt/lists/*

# Change ownership of the src directory to $DEVELOPMENT_USERNAME
RUN chown -R $DEVELOPMENT_USERNAME:$DEVELOPMENT_USERNAME /${BOT_NAME}

# Set up autocompletion for user
RUN apt-get update && apt-get install -y git-core bash-completion \
  && echo "if [ -f /opt/ros/${ROS_DISTRO}/setup.bash ]; then source /opt/ros/${ROS_DISTRO}/setup.bash; fi" >> /home/$DEVELOPMENT_USERNAME/.bashrc \
  && echo "if [ -f /usr/share/colcon_argcomplete/hook/colcon-argcomplete.bash ]; then source /usr/share/colcon_argcomplete/hook/colcon-argcomplete.bash; fi" >> /home/$DEVELOPMENT_USERNAME/.bashrc \
  && rm -rf /var/lib/apt/lists/* 

ENV DEBIAN_FRONTEND=
ENV AMENT_CPPCHECK_ALLOW_SLOW_VERSIONS=1






###########################################
#  Deployment image
###########################################
FROM overlay AS deploy



ARG ROS_DISTRO
ARG BOT_NAME

ENV ROS_DISTRO=${ROS_DISTRO}
SHELL ["/bin/bash", "-c"]
 
# Create Colcon workspace with external dependencies
RUN mkdir -p /${BOT_NAME}/src
WORKDIR /${BOT_NAME}/src

 
# Build the base Colcon workspace, installing dependencies first.
WORKDIR /${BOT_NAME}
RUN source /opt/ros/${ROS_DISTRO}/setup.bash \
 && apt-get update -y \
 && rosdep install --from-paths src --ignore-src --rosdistro ${ROS_DISTRO} -y \
 && colcon build --symlink-install



RUN colcon build 
 ##--install-base /somewhere yuou like or in the /opt/ros/ # them remove the source codes,, 

RUN source install/setup.bash

RUN rm -rf /${BOT_NAME}/{src,log,build}


RUN echo "if [ -f /opt/ros/${ROS_DISTRO}/setup.bash ]; then source /opt/ros/${ROS_DISTRO}/setup.bash; fi" >> /root/.bashrc \
    && echo "if [ -f /${BOT_NAME}/src/setup.bash ]; then source /${BOT_NAME}/src/setup.bash ; fi" >> /root/.bashrc


#  yeah moved ## older:should have move the colcon build in the install base to the github action so that it will be build there ...
#  one work pending that is the entrypoint which may be a bash script that launches dyno atman service. 
#   (all the other things will be taken care using the install.sh script)


# to do : have to decide and set the username for the deploy/release container, one who runs the startup service of our robot

# have to change the deploy to release





### 1) this is a dockerfile created for the purpose of aiding the development and deployment of the dyno atman

# i) it require the source code to be available using the dependencies.repo 
