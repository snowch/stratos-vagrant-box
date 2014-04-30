#!/bin/bash

# fail on error
set -e

# clear logs
echo > stratos.log > test.log

echo "Destroying previous virtual machines"
vagrant destroy -f >> stratos.log 2>&1

echo "Starting new virtual machine"
vagrant up >> stratos.log 2>&1

{
############### 
# Stratos Setup
###############

echo "Starting Stratos setup"
vagrant ssh -c "./stratos.sh -f" >> stratos.log 2>&1
# '-d' sets up eclipse and lubuntu.  the next line can be commented 
# out if you just want a runtime environment
vagrant ssh -c "./stratos.sh -d" >> stratos.log 2>&1

################# 
# OpenStack Setup
#################

echo "Setting up kernel for Docker"
vagrant ssh -c "./openstack-docker.sh -o" >> stratos.log 2>&1 

echo "Rebooting after new kernel installation"
vagrant reload >> stratos.log 2>&1

echo "Setting up docker"
vagrant ssh -c "./openstack-docker.sh -o && ./openstack-docker.sh -d" >> stratos.log 2>&1

################# 
# Tests
#################

# start stratos
vagrant ssh -c "./stratos.sh -s" >> stratos.log 2>&1
# TODO - shouldn't rely on sleeping
sleep 5m
vagrant ssh -c ". /vagrant/tests/test_stratos.sh" >> test.log 2>&1

} & # run whole setup in the background

echo "See stratos.log and test.log for build output."
