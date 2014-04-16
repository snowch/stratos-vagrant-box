#!/bin/bash
mkdir p - /root/lib
cp -f /lib/x86_64-linux-gnu/libnss_files.so.2 /root/lib
perl -pi -e 's:/etc/hosts:/tmp/hosts:g' /root/lib/libnss_files.so.2
perl -pi -e 's:/etc/resolv.conf:/tmp/resolv.conf:g' /root/lib/libnss_files.so.2
cp -f /etc/hosts /tmp/hosts
cp -f /etc/resolv.conf /tmp/resolv.conf
