#!/bin/bash

# Function to install packages from a list
install_packages() {
    # Get the name of the list variable
    local list_name="$1[@]"
    # Get the list of packages
    local packages=("${!list_name}")
    
    # Iterate over the list and install each package
    for package in "${packages[@]}"; do
        apt install -y "$package"
    done
}

# Source the packages file
source dependencies.sh

# Check if the environment is set to develop
if [[ "$MODE" == "develop" ]]; then
    # Install development dependencies
    install_packages dev_packages
fi


# Install deployment dependencies
install_packages deploy_packages