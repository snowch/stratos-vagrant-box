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

    -f perform a complete setup of the stratos runtime environment

    -h show this help message

All commands can be re-run as often as required.
EOF
   exit 0
}

function initial_setup() {
   
   echo -e "\e[32mPerforming initial setup.\e[39m"

   sudo apt-get update

   # is 3.8.0-26 kernel installed 
   #dpkg --get-selections | grep linux-image-3.8.0-26-generic | grep -v deinstall

   dpkg -s "linux-image-3.8.0-26-generic" >/dev/null || 
   { 
     sudo apt-get install -y linux-image-3.8.0-26-generic linux-headers-3.8.0-26-generic linux-image-extra-3.8.0-26-generic

     sudo groupadd docker
     sudo usermod -a -G docker vagrant

     echo "Reboot required."
     echo "Exit ssh, perform 'vagrant reload' then ssh back in and re-run this script." 
     exit 0
   } 

   sudo apt-get install -y git

   if [ ! -d devstack ]
   then
     git clone https://github.com/openstack-dev/devstack.git
   fi

   cd devstack
   git checkout stable/havana

   NOVA_DOCKER_CFG=/home/vagrant/devstack/lib/nova_plugins/hypervisor-docker

   # Patch to user newer docker version

   grep -q '^DOCKER_PACKAGE_VERSION=' $NOVA_DOCKER_CFG
   if [ $? -eq 0 ]
   then
      sed -i -e s/^DOCKER_PACKAGE_VERSION.*$/DOCKER_PACKAGE_VERSION=0.7.6/g $NOVA_DOCKER_CFG
   else
      sed -i -e s/^\(DOCKER_DIR=.*\)$/DOCKER_PACKAGE_VERSION=0.7.6\n\1/g $NOVA_DOCKER_CFG
   fi

   # Patch devstack broken scripts

   sed -i -e "s/lxc-docker;/lxc-docker-\$\{DOCKER_PACKAGE_VERSION\};/g" $NOVA_DOCKER_CFG
   sed -i -e "s/lxc-docker=/lxc-docker-/g" /home/vagrant/devstack/tools/docker/install_docker.sh

   # Use Damitha's scripts for the actuall install
   # Source: http://damithakumarage.wordpress.com/2014/01/31/how-to-setup-openstack-havana-with-docker-driver/

   cp -f /vagrant/openstack/install_docker0.sh /home/vagrant/devstack/tools/docker/
   cp -f /vagrant/openstack/install_docker1.sh /home/vagrant/devstack/tools/docker/

   # docker scripts need curl 
   sudo apt-get install -y curl

   wget -c http://get.docker.io/images/openstack/docker-registry.tar.gz -P /home/vagrant/devstack/files/
   wget -c http://get.docker.io/images/openstack/docker-ut.tar.gz -P /home/vagrant/devstack/files

   ./tools/docker/install_docker0.sh

   sudo chown vagrant:docker /var/run/docker.sock

   ./tools/docker/install_docker1.sh

   sudo service docker restart

   # need to wait for docker to start, or following
   # chown will be overwritten
   sleep 3

   sudo chown vagrant:docker /var/run/docker.sock

   cd files

   docker import - docker-registry < ./docker-registry.tar.gz
   docker import - docker-busybox < ./docker-ut.tar.gz

   sudo sed -i 's/#net.ipv4.ip_forward/net.ipv4.ip_forward/g' /etc/sysctl.conf
   sudo sysctl -p /etc/sysctl.conf

   sudo apt-get install -y lxc wget bsdtar curl
   sudo apt-get install -y linux-image-extra-3.8.0-26-generic

   sudo modprobe aufs

   set +e 
   grep -q 'modprobe aufs' /etc/rc.local
   if [ $? == 1 ]
   then
     sudo sh -c "cat > /etc/rc.local" <<EOF
#!/bin/sh -e
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will "exit 0" on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution
# bits.
#
# By default this script does nothing.

modprobe aufs
sudo killall dnsmasq
sudo chown vagrant:docker /var/run/docker.sock

exit 0
EOF
   fi
   set -e

   cat > /home/vagrant/devstack/localrc <<EOF
FLOATING_RANGE=192.168.92.0/27
FIXED_RANGE=10.11.12.0/24
FIXED_NETWORK_SIZE=256
FLAT_INTERFACE=eth2
ADMIN_PASSWORD=g
MYSQL_PASSWORD=g
RABBIT_PASSWORD=g
SERVICE_PASSWORD=g
SERVICE_TOKEN=g
SCHEDULER=nova.scheduler.filter_scheduler.FilterScheduler
VIRT_DRIVER=docker
SCREEN_LOGDIR=$DEST/logs/screen
EOF

   cd /home/vagrant/devstack
   ./stack.sh

   echo "=============================================="
   echo "Openstack installation finished.  Login using:"
   echo ""
   echo "URL http://192.168.92.30/"
   echo "Username: admin or demo"
   echo "Passsword: g"
   echo "=============================================="
 

}

main "$@"
