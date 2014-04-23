#!/bin/bash

vagrant destroy -f && \
  vagrant up && \
  vagrant ssh -c "./stratos_dev.sh -f" && \
  vagrant ssh -c "./openstack-qemu.sh -f"
