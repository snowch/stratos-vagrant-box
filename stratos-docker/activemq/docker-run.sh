#!/bin/bash

sudo docker.io run -p=61616:61616 -p=8161:8161 -d apache-stratos/activemq
