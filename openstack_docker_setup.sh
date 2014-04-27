#!/bin/sh

vagrant destroy openstack -f && \
vagrant up openstack && \
vagrant ssh -c "./openstack-docker.sh -o" openstack && \
vagrant reload openstack && \
vagrant ssh -c "./openstack-docker.sh -d" openstack
