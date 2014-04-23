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

BASE_IMAGE_NAME='Ubuntu 12.04 64bit'
CARTRIDGE_IMAGE_NAME='Ubuntu 12.04 64bit Cartridge'

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
  while getopts 'fodch' flag; do
    progarg=${flag}
    case "${flag}" in
      f) full_setup; exit $? ;;
      o) devstack_setup "True"; exit $? ;;
      d) devstack_setup "False"; exit $? ;;
      c) create_cartridge; exit $? ;;
      h) usage ; exit $? ;;
      \?) usage ; exit $? ;;
      *) usage ; exit $? ;;
    esac
  done
  usage
}

function usage () {
   cat <<EOF
Usage: $progname -[f|o|d|c|h]

Where:

    -f Perform a complete online setup of openstack and create a cartridge
       This command is the equivalent of running:

       $progname -d && $progname -c

    -d Perform a complete online setup of openstack

    -o Perform a complete offline setup of the runtime environment
       (online setup needs to have been done at least once first) 

    -c Create cartridge

    -h Show this help message

All commands can be re-run as often as required.
EOF
   exit 0
}

function full_setup() {
   devstack_setup
   create_cartridge
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
FLOATING_RANGE=192.168.92.8/29
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
#OFFLINE=$offline
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

function create_cartridge() {

   pushd $PWD

   sudo apt-get update
   sudo apt-get install -y nmap

   set +u
   . ${DEVSTACK_HOME}/openrc admin admin
   set -u

   # remove any left-over instances from previous runs
   echo "Cleaning up from previous runs."
   set +e
   nova delete 'ubuntu'
   nova image-delete "$BASE_IMAGE_NAME"
   nova image-delete "$CARTRIDGE_IMAGE_NAME"
   set -e

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
   image=$(nova image-list | grep "$BASE_IMAGE_NAME" | cut -d'|' -f2)

   if [ -z "$image" ]
   then
     glance image-create --name "$BASE_IMAGE_NAME" --is-public true --disk-format qcow2 --container-format bare --file /home/vagrant/precise-server-cloudimg-amd64-disk1.img
   fi

   if ! $(nova keypair-list | grep -q 'openstack-demo-keypair'); then
     chmod 600 openstack-demo-keypair.pem
     nova keypair-add --pub_key openstack-demo-keypair.pem 'openstack-demo-keypair'
   fi

   if [[ -z $(nova flavor-list | grep 'm1.cartridge') ]]; then
     nova flavor-create m1.cartridge 18 512 0 1
   fi

   if ! (nova list | grep -q ubuntu); then
     # start an instance
     flavor=$(nova flavor-list | grep 'm1.cartridge' | cut -d'|' -f2)
     image=$(nova image-list | grep "$BASE_IMAGE_NAME" | cut -d'|' -f2)
     nova boot --flavor $flavor --key-name openstack-demo-keypair --image $image ubuntu
   fi

   while : ; do
     status=$(nova list | grep 'ubuntu' | cut -d'|' -f4)
     if [[ $status =~ (ERROR|SHUTOFF) ]]; then
        echo "Error starting instance. Calling 'nova list':"
        nova list | grep 'ubuntu' 
        exit -1
     elif [ $status == "ACTIVE" ]; then
        break
     fi
     echo "Waiting for the instance to startup. Current status is: " $status
     sleep 10s
   done
   echo "Instance has started ..."

   instance_ip=$(nova list | grep 'ubuntu' | cut -d'|' -f7 | cut -d= -f2 | tr -d ' ')
   # clear previous known_hosts entries
   ssh-keygen -f "/home/vagrant/.ssh/known_hosts" -R 10.11.12.2
   echo "You can connect using: 'ssh -i openstack-demo-keypair.pem ubuntu@$instance_ip'"

   # wait for the guest OS and ssh server to start
   count=0
   until [ $(nmap --open -p 22 $instance_ip |grep -c "ssh") -eq 1 ]
   do 
     let "count=count+1"
     if [ $count -eq 100 ]
     then
       echo "Retry count failed waiting for ssh on $instance_ip"
       exit 1
     fi
     sleep 10s 
     echo "Waiting for ssh port to open on $instance_ip"
   done 

CMDS=$(cat <<"CMD"

url='https://git-wip-us.apache.org/repos/asf?p=incubator-stratos.git;a=blob_plain;f=tools/puppet3-agent'
sudo bash -x -c "

# fail on error
set -e

echo \"export LC_ALL=\"en_US.UTF-8\"\" >> /root/.bashrc
source /root/.bashrc

apt-get update

export count=0
until [ \$(apt-get install -y zip unzip expect) -eq 0 ]
do 
  let \"count=count+1\"
  if [ \$count -eq 20 ]
  then
    echo 'Retry count failed trying to install packages.'
    exit 1
  fi
  sleep 10s 
  echo 'Failed to install packages.  Retrying.'
done 

if [ -e /root/bin ]; then
  rm -rf /root/bin
fi

mkdir -p /root/bin
cd /root/bin

wget -nv '${url}/config.sh;hb=HEAD' -O config.sh
wget -nv '${url}/init.sh;hb=HEAD' -O init.sh
chmod +x config.sh
chmod +x init.sh
mkdir -p /root/bin/puppetinstall
wget -nv '${url}/puppetinstall/puppetinstall;hb=HEAD' -O puppetinstall/puppetinstall
wget -nv '${url}/stratos_sendinfo.rb;hb=HEAD' -O stratos_sendinfo.rb
chmod +x puppetinstall/puppetinstall

sed -i 's:^TIMEZONE=.*$:TIMEZONE=\"Etc/UTC\":g' /root/bin/puppetinstall/puppetinstall
"
CMD
) 

   echo "Starting to configure the cartridge"
   ssh -oStrictHostKeyChecking=no -i openstack-demo-keypair.pem ubuntu@$instance_ip -t "$CMDS"

   nova reboot --poll ubuntu
   instance_ip=$(nova list | grep 'ubuntu' | cut -d'|' -f7 | cut -d= -f2)
   # wait for the guest OS and ssh server to start
   # TODO refactor this duplicated code to a function
   count=0
   until [ $(nmap --open -p 22 $instance_ip |grep -c "ssh") -eq 1 ]
   do 
     let "count=count+1"
     if [ $count -eq 100 ]
     then
       echo "Retry count failed waiting for ssh to $instance_ip"
       exit 1
     fi
     sleep 10s 
     echo "Waiting for ssh connection to $instance_ip"
   done 

EXPECT_SCRIPT=$(cat <<'END'
#!/usr/bin/expect
set timeout -1
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
# catch errors and return to caller
catch wait result
exit [lindex $result 3]
END
) 

   echo "$EXPECT_SCRIPT" | ssh -oStrictHostKeyChecking=no -i openstack-demo-keypair.pem ubuntu@$instance_ip "cat > /home/ubuntu/config.exp"

   ssh -oStrictHostKeyChecking=no -i openstack-demo-keypair.pem ubuntu@$instance_ip "sudo expect /home/ubuntu/config.exp"


   cartridge_image=$(nova image-list | grep "$CARTRIDGE_IMAGE_NAME" | cut -d'|' -f2)

   if [ ! -z "$cartridge_image" ]
   then
     echo "Found an old cartridge image so deleting it."
     nova image-delete $cartridge_image
   fi

   # TODO use --poll option to remove need for while loop
   nova image-create ubuntu "$CARTRIDGE_IMAGE_NAME" 
   cartridge_image=$(nova image-list | grep "$CARTRIDGE_IMAGE_NAME" | cut -d'|' -f2)

   while : ; do
     status=$(glance image-list | grep "$CARTRIDGE_IMAGE_NAME" | cut -d'|' -f7)
     if [ $status == "active" ]; then
        break
     fi
     echo "Waiting for the instance image upload to complete.  Status is: " $status
     sleep 10s
   done
   echo "Image has been uploaded"

   # make image public
   glance image-update $cartridge_image --is-public=true

   # shut off the instance - we don't need it now
   nova stop ubuntu
   nova delete ubuntu

   echo "Finished configuring the cartridge."
   echo "Note the cartridge id: $cartridge_image"

#set -u

   popd
}

main "$@"
