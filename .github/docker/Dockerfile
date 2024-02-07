FROM ros:humble

ARG USERNAME=questbot
ARG USER_UID=1000
ARG USER_GID=$USER_UID
ARG USER_REPO=

# Create the user
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME 

# [Optional] Add sudo support. Omit if you don't need to install software after connecting.
RUN apt-get update \
    && apt-get install -y sudo \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

RUN apt-get update && apt-get upgrade -y
RUN apt-get install -y python3-pip
ENV SHELL /bin/bash

#configs
COPY /config/bashrc /home/$USERNAME/.bashrc

WORKDIR /home/dyno/ws/src


###install user softwares###

#basic tools
RUN apt-get update && apt-get -y install \
    git \
    nano \
    joystick \
    jstest-gtk \
    tmux \
    bash-completion \
    python3-argcomplete \
    iputils-ping \
    net-tools 

#ros tools
RUN apt-get update && apt-get install -y \
    ros-humble-rviz2 \
    ros-humble-turtlesim 

#fix issues
RUN apt-get update && apt-get install -y \
    libogre1.12.10 #for rviz

#entrypoing for image
ENTRYPOINT ["/bin/bash", "-i", "-c", "source /home/$USERNAME/.bashrc"]

#user create
USER $USERNAME
