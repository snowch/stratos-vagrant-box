#!/bin/sh

TYPE=$1

DATE=$(echo $(date) | sed -e 's@ @_@g' -e 's@:@_@g')

ifconfig > ifconfig.$DATE.$TYPE
netstat -nr > netstat.$DATE.$TYPE
