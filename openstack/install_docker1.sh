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

echo "Waiting for docker daemon to start..."
CONFIGURE_CMD="while ! /bin/echo -e 'GET /v1.3/version HTTP/1.0\n\n' | socat - unix-connect:$DOCKER_UNIX_SOCKET | grep -q '200 OK'; do
    # Set the right group on docker unix socket before retrying
    echo "failed"
    sleep 1
done"
if ! timeout $SERVICE_TIMEOUT sh -c "$CONFIGURE_CMD"; then
    die $LINENO "docker did not start"
fi

