#!/bin/bash

# **install_docker.sh** - Do the initial Docker installation and configuration

# install_docker.sh
#
# Install docker package and images
# * downloads a base busybox image and a glance registry image if necessary
# * install the images in Docker's image cache


# Keep track of the current directory
SCRIPT_DIR=$(cd $(dirname "$0") && pwd)
TOP_DIR=$(cd $SCRIPT_DIR/../..; pwd)

# Import common functions
source $TOP_DIR/functions

# Load local configuration
source $TOP_DIR/stackrc

FILES=$TOP_DIR/files

# Get our defaults
source $TOP_DIR/lib/nova_plugins/hypervisor-docker

SERVICE_TIMEOUT=${SERVICE_TIMEOUT:-60}


# Install Docker Service
# ======================

# Stop the auto-repo updates and do it when required here
NO_UPDATE_REPOS=True

# Set up home repo
curl https://get.docker.io/gpg | sudo apt-key add -
install_package python-software-properties && \
    sudo sh -c "echo deb $DOCKER_APT_REPO docker main > /etc/apt/sources.list.d/docker.list"
apt_get update
install_package --force-yes lxc-docker-${DOCKER_PACKAGE_VERSION} socat

