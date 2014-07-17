#!/bin/bash

if ! which docker.io; then
   sudo apt-get update
   sudo apt-get install -y docker.io
fi

sudo docker.io build -t=apachestratos/activemq .
sudo docker.io push apachestratos/activemq
