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
  while getopts 'fdih' flag; do
    progarg=${flag}
    case "${flag}" in
      f) full_setup; exit $? ;;
      d) devstack_setup; exit $? ;;
      i) start_instance; exit $? ;;
      h) usage ; exit $? ;;
      \?) usage ; exit $? ;;
      *) usage ; exit $? ;;
    esac
  done
  usage
}

function usage () {
   cat <<EOF
Usage: $progname -[f|d|i|h]

Where:

    -f perform a complete setup of the openstack runtime environment

    -d perform devstack setup

    -i setup images and start instance

    -h show this help message

All commands can be re-run as often as required.
EOF
   exit 0
}

function full_setup() {
   devstack_setup
   start_instance
}

function devstack_setup() {
   
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

   echo "============================================="
   echo "Openstack installation finished. Login using:"
   echo ""
   echo "URL http://192.168.92.30/"
   echo "Username: admin or demo"
   echo "Passsword: g"
   echo "============================================="
}

function start_instance() {

   set +u
   . ${DEVSTACK_HOME}/openrc
   set -u

   if ! $(nova secgroup-list-rules default | grep -q 'tcp'); then
     nova secgroup-add-rule default tcp 22 22 0.0.0.0/0
   fi

   if ! $(nova secgroup-list-rules default | grep -q 'icmp'); then
     nova secgroup-add-rule default icmp -1 -1 0.0.0.0/0
   fi

   echo "Starting Ubuntu image download"

   # From: http://docs.openstack.org/image-guide/content/ch_obtaining_images.html#ubuntu-images
   wget -nv -c http://uec-images.ubuntu.com/precise/current/precise-server-cloudimg-amd64-disk1.img

   echo "Finished Ubuntu image download"

   # check we haven't already added the image
   image=$(nova image-list | grep 'Ubuntu 12.04 64bit' | cut -d'|' -f2)

   if [ -z "$image" ]
   then
     glance image-create --name "Ubuntu 12.04 64bit" --is-public true --disk-format qcow2 --container-format bare --file /home/vagrant/precise-server-cloudimg-amd64-disk1.img
   fi

   # create keypair for 'demo' user.  note: keypair not visible to 'admin' user.
   nova keypair-add "openstack-demo-keypair" > openstack-demo-keypair.pem
   chmod 600 openstack-demo-keypair.pem

   # start an instance
   flavor=$(nova flavor-list | grep 'm1.micro' | cut -d'|' -f2)
   image=$(nova image-list | grep 'Ubuntu 12.04 64bit' | cut -d'|' -f2)
   nova boot --flavor $flavor --key-name openstack-demo-keypair --image $image ubuntu

   while : ; do
     status=$(nova list | grep 'ubuntu' | cut -d'|' -f4)
     if [ $status == "ERROR" ]; then
        echo "Error starting instance"
        exit -1
     elif [ $status == "ACTIVE" ]; then
        break
     fi
     echo "Waiting for the instance to startup. Current status is: " $status
     sleep 10s
   done
   echo "Instance has started ..."

   instance_ip=$(nova list | grep 'ubuntu' | cut -d'|' -f7 | cut -d= -f2)
   echo "Connect using: "
   echo "ssh -i openstack-demo-keypair.pem ubuntu@$instance_ip"
}

main "$@"
