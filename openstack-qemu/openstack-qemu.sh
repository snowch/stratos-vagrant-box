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
  while getopts 'fodih' flag; do
    progarg=${flag}
    case "${flag}" in
      f) full_setup; exit $? ;;
      o) devstack_setup "True"; exit $? ;;
      d) devstack_setup "False"; exit $? ;;
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
Usage: $progname -[f|o|d|i|h]

Where:

    -f perform a complete setup of the openstack runtime environment

    -o perform a complete offline setup of the runtime environment

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

   set +u
   offline=$1
   set -u

   pushd $PWD
   
   echo -e "\e[32mPerforming initial setup.\e[39m"

   # ensure guests have access to outside world
   sudo sed -i "s/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g" /etc/sysctl.conf
   sudo sysctl -w net.ipv4.ip_forward=1
   # TODO make this change permanent
   sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE


   sudo apt-get update
   sudo apt-get install -y git

   if [ ! -d devstack ]
   then
     git clone https://github.com/openstack-dev/devstack.git
   fi

   cd devstack
   git checkout stable/havana

   cat > ${HOME}/devstack/localrc <<EOF
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
SCREEN_LOGDIR=\$DEST/logs/screen
OFFLINE=$offline
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

   popd
}

function start_instance() {

   pushd $PWD

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
   # FIXME: make this idempotent
   if [ ! -e openstack-demo-keypair.pem ]
   then
     nova keypair-add "openstack-demo-keypair" > openstack-demo-keypair.pem
     chmod 600 openstack-demo-keypair.pem
   fi

   if ! (nova list | grep -q ubuntu); then
     # start an instance
     flavor=$(nova flavor-list | grep 'm1.micro' | cut -d'|' -f2)
     image=$(nova image-list | grep 'Ubuntu 12.04 64bit' | cut -d'|' -f2)
     nova boot --flavor $flavor --key-name openstack-demo-keypair --image $image ubuntu
   fi

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

   # hack to prevent no route to host error
   sleep 60s
   ping -c1 $instance_ip

#set +u

CMDS=$(cat <<"CMD"

url='https://git-wip-us.apache.org/repos/asf?p=incubator-stratos.git;a=blob_plain;f=tools/puppet3-agent'
sudo bash -x -c "

apt-get update
apt-get install -y zip unzip expect

if [ -e /root/bin ]; then
  rm -rf /root/bin
fi

mkdir -p /root/bin
cd /root/bin

wget '${url}/config.sh;hb=HEAD' -O config.sh
wget '${url}/init.sh;hb=HEAD' -O init.sh
chmod +x config.sh
chmod +x init.sh
mkdir -p /root/bin/puppetinstall
wget '${url}/puppetinstall/puppetinstall;hb=HEAD' -O puppetinstall/puppetinstall
wget '${url}/stratos_sendinfo.rb;hb=HEAD' -O stratos_sendinfo.rb
chmod +x puppetinstall/puppetinstall
"
CMD
) 

   echo "Starting to configure the cartridge"
   ssh -oStrictHostKeyChecking=no -i openstack-demo-keypair.pem ubuntu@$instance_ip -t "$CMDS"

EXPECT_SCRIPT=$(cat <<END
#!/bin/bin/expect
spawn /root/bin/config.sh
expect "This script will install and configure puppet agent, do you want to continue *"
send "y\r"
expect "Please provide stratos service-name:"
send "php\r"
expect "Please provide puppet master IP:"
send "192.168.56.5\r"
expect "Please provide puppet master hostname *"
send "puppet.stratos.com\r"
expect eof
END
) 

   echo "$EXPECT_SCRIPT" | ssh -oStrictHostKeyChecking=no -i openstack-demo-keypair.pem ubuntu@$instance_ip "cat > /home/ubuntu/config.exp"

   ssh -oStrictHostKeyChecking=no -i openstack-demo-keypair.pem ubuntu@$instance_ip "sudo expect /home/ubuntu/config.exp"

   echo "Finished configuring the cartridge"

#set -u

   popd
}

main "$@"
