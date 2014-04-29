#!/bin/bash

# fail on error
set -e

echo "Starting build.  Please be patient."

vagrant destroy -f stratos > stratos.log 2>&1
vagrant up stratos >> stratos.log 2>&1

vagrant destroy -f openstack > openstack.log 2>&1
vagrant up openstack >> openstack.log 2>&1

{ 
  # we can run the stratos build in the background
  vagrant ssh -c "./stratos.sh -f && ./stratos.sh -d" stratos >> stratos.log 2>&1
} &

{ 
  # first run with '-o' sets up the kernel
  vagrant ssh -c "./openstack-docker.sh -o" openstack >> openstack.log 2>&1 
  # reboot after setting up the kernel
  vagrant reload openstack >> openstack.log 2>&1
  # finish the openstack setup in the background
  vagrant ssh -c "./openstack-docker.sh -o && ./openstack-docker.sh -d" openstack >> openstack.log 2>&1&
} &

echo "Building Stratos and OpenStack instances."
echo "See stratos.log and openstack.log for build output."
