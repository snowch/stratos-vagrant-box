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

# instructions taken from: http://docs.cloudstack.apache.org/projects/cloudstack-installation/en/latest/installation.html

#
# Add cloudstack repository
#

sudo sh -c \
  "echo 'deb http://cloudstack.apt-get.eu/ubuntu precise 4.2' > /etc/apt/sources.list.d/cloudstack.list"

sudo sh -c \
  "wget -O - http://cloudstack.apt-get.eu/release.asc|apt-key add -"

sudo apt-get update

#
# Cloudstack Management Server
#

sudo sh -c "
   export DEBIAN_FRONTEND=noninteractive
   echo mysql-server-5.1 mysql-server/root_password password password | debconf-set-selections
   echo mysql-server-5.1 mysql-server/root_password_again password password | debconf-set-selections
   apt-get -y install mysql-server
   "

sudo apt-get install -y openntpd cloudstack-management

sudo sh -c "cat > /etc/mysql/conf.d/cloudstack.cnf" <<EOF
innodb_rollback_on_timeout=1
innodb_lock_wait_timeout=600
max_connections=350
log-bin=mysql-bin
binlog-format = 'ROW'
EOF

sudo service mysql restart

sudo cloudstack-setup-databases cloud:password@localhost \
  --deploy-as=root:password 

sudo sh -c \
  "grep 'Defaults:cloud !requiretty' /etc/sudoers || echo 'Defaults:cloud !requiretty' >> /etc/sudoers"

sudo cloudstack-setup-management

#
# Setup NFS
#

sudo apt-get install -y nfs-kernel-server rpcbind

sudo mkdir -p /export/primary
sudo mkdir -p /export/secondary

sudo sh -c \
  "grep '/export  *(rw,async,no_root_squash,no_subtree_check)' /etc/exports || echo '/export  *(rw,async,no_root_squash,no_subtree_check)' > /etc/exports"

sudo exportfs -a

function set_nfs_vars() {
  var=$1
  sudo sh -c "grep '$var' /etc/default/nfs-kernel-server || echo '$var' >> /etc/default/nfs-kernel-server"
}

set_nfs_vars 'LOCKD_TCPPORT=32803'
set_nfs_vars 'LOCKD_UDPPORT=32769'
set_nfs_vars 'MOUNTD_PORT=892'
set_nfs_vars 'RQUOTAD_PORT=875'
set_nfs_vars 'STATD_PORT=662'
set_nfs_vars 'STATD_OUTGOING_PORT=2020'


sudo sh -c "cat > /etc/mysql/conf.d/cloudstack.cnf" <<"EOF"
[General]

Verbosity = 0
Pipefs-Directory = /run/rpc_pipefs
# set your own domain here, if id differs from FQDN minus hostname
Domain = $(hostname -d)

[Mapping]
EOF


sudo /etc/init.d/nfs-kernel-server restart

[ -d /mnt/primary ] || sudo mkdir /mnt/primary
[ -d /mnt/secondary ] || sudo mkdir /mnt/secondary

sudo mount -t nfs localhost:/export/primary /mnt/primary
sudo mount -t nfs localhost:/export/secondary /mnt/secondary

sudo /usr/share/cloudstack-common/scripts/storage/secondary/cloud-install-sys-tmplt -m /mnt/secondary -u http://download.cloud.com/templates/4.3/systemvm64template-2014-01-14-master-kvm.qcow2.bz2 -h kvm -F

sudo umount /mnt/primary
sudo umount /mnt/secondary

#
# Install KVM
#

sudo apt-get install -y cloudstack-agent

function set_libvirt_vars() {
  var=$1
  var_name=$(echo $var | cut -f1 -d' ')
  # if var exists, update it
  sudo sed -i -e "s/^$var_name.*$/$var/" /etc/libvirt/libvirtd.conf
  # if var doesn't exist, create it
  sudo sh -c "grep '$var' /etc/libvirt/libvirtd.conf || echo '$var' >> /etc/libvirt/libvirtd.conf"
}

set_libvirt_vars 'listen_tls = 0'
set_libvirt_vars 'listen_tcp = 1'
set_libvirt_vars 'tcp_port = "16509"'
set_libvirt_vars 'auth_tcp = "none"'
set_libvirt_vars 'mdns_adv = 0'

sudo sed -i -e 's/^libvirtd_opts="-d"/libvirtd_opts="-d -l"/' /etc/default/libvirt-bin

sudo service libvirt-bin restart

sudo ln -s /etc/apparmor.d/usr.sbin.libvirtd /etc/apparmor.d/disable/
sudo ln -s /etc/apparmor.d/usr.lib.libvirt.virt-aa-helper /etc/apparmor.d/disable/
sudo apparmor_parser -R /etc/apparmor.d/usr.sbin.libvirtd
sudo apparmor_parser -R /etc/apparmor.d/usr.lib.libvirt.virt-aa-helper

mysql -u root -p'password' -e "INSERT INTO cloud.configuration (category, instance, component, name, value, description) VALUES ('Advanced', 'DEFAULT', 'management-server', 'xen.check.hvm', 'false', 'Shoud we allow only the XenServers support HVM');"

#
# network bridges
#

TODO

#
# echo UI URL
#

ip=$(ip addr list eth1 |grep "inet " |cut -d' ' -f6|cut -d/ -f1)

out="Cloudstack URL available on: http://${ip}:8080/client"

echo  $(yes = | head -${#out} | tr -d "\n") # surround text below with '='
echo "Cloudstack URL available on: http://${ip}:8080/client"
echo "Username: admin"
echo "Password: password"
echo  $(yes = | head -${#out} | tr -d "\n") # surround text above with '='
