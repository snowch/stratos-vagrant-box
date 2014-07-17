#!/bin/bash

if ! which docker.io; then
   sudo apt-get update
   sudo apt-get install -y docker.io
fi

sudo docker.io build -t=apachestratos/mysql .
sudo docker.io push apachestratos/mysql
