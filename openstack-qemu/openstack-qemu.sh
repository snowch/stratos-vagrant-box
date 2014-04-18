#!/bin/bash
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

set -e
set -u

DEVSTACK_HOME=${HOME}/devstack
STRATOS_BASE=${HOME}/stratosbase

progname=$0
progdir=$(dirname $progname)
progdir=$(cd $progdir && pwd -P || echo $progdir)
progarg=''

function finish {
   echo "\n\nReceived SIGINT. Exiting..."
   exit
}

trap finish SIGINT

function main() {
  while getopts 'fh' flag; do
    progarg=${flag}
    case "${flag}" in
      f) initial_setup ; exit $? ;;
      h) usage ; exit $? ;;
      \?) usage ; exit $? ;;
      *) usage ; exit $? ;;
    esac
  done
  usage
}

function usage () {
   cat <<EOF
Usage: $progname -[f|h]

Where:

    -f perform a complete setup of the openstack runtime environment

    -h show this help message

All commands can be re-run as often as required.
EOF
   exit 0
}

function initial_setup() {
   
   echo -e "\e[32mPerforming initial setup.\e[39m"

   sudo apt-get update

   sudo apt-get install -y git

   if [ ! -d devstack ]
   then
     git clone https://github.com/openstack-dev/devstack.git
   fi

   cd devstack
   git checkout stable/havana

   cat > ${HOME}/devstack/localrc <<'EOF'
HOST_IP=192.168.92.30
FLOATING_RANGE=192.168.92.0/27
FIXED_RANGE=10.11.12.0/24
FIXED_NETWORK_SIZE=256
FLAT_INTERFACE=eth2
ADMIN_PASSWORD=g
# stratos_dev.sh script uses 'password' for mysql
MYSQL_PASSWORD=password
RABBIT_PASSWORD=g
SERVICE_PASSWORD=g
SERVICE_TOKEN=g
#SCHEDULER=nova.scheduler.filter_scheduler.FilterScheduler
SCREEN_LOGDIR=$DEST/logs/screen
#OFFLINE=True
EOF

   cd ${HOME}/devstack
   ./stack.sh

   set +u
   . ${DEVSTACK_HOME}/openrc
   set -u

   nova secgroup-add-rule default tcp 22 22 0.0.0.0/0
   nova secgroup-add-rule default icmp -1 -1 0.0.0.0/0

   echo "============================================="
   echo "Openstack installation finished. Login using:"
   echo ""
   echo "URL http://192.168.92.30/"
   echo "Username: admin or demo"
   echo "Passsword: g"
   echo "============================================="
 

}

main "$@"
