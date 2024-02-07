FROM ros:humble

ARG USERNAME=questbot
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Create the user && config which is nessesary for some pkgs
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && mkdir /home/$USERNAME/.config && chown $USER_UID:$USER_GID /home/$USERNAME/.config

# adding the user to sudo group
RUN apt-get update \
    && apt-get install -y sudo \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME \
    && rm -rf /var/lib/apt/lists/*

# installing language && installing timezone already done in ros image
# RUN ....

#installing softwares needed

RUN apt-get update && apt-get upgrade -y \
    apt-get install -y \
    python3-pip \
    git \
    nano 

USER $USERNAME
