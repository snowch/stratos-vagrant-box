#!/bin/bash

vagrant destroy -f && \
  vagrant up && \
  vagrant ssh -c "./stratos.sh -f && ./openstack-qemu.sh -f"
