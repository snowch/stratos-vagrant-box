#!/bin/bash
NOVA_NIC=$(ip a | grep pvnet | head -n 1 | cut -d: -f2)
while [ "$NOVA_NIC" == "" ] ; do
   echo "Find nova NIC..."
   sleep 1
   NOVA_NIC=$(ip a | grep pvnet | head -n 1 | cut -d: -f2)
done
echo $NOVA_NIC
echo "Device $NOVA_NIC found. Wait until ready."
sleep 3
# Setup a network route to insure we use the nova network.
#
echo "[INFO] Create default route for $NOVA_NIC. Gateway 10.11.12.1"
ip r r default via 10.11.12.1 dev $NOVA_NIC
# Shutdown eth0 since icps will fetch enabled enterface for streaming.
ip l set down dev eth0

sleep 5
#Get public keys from meta-data server
if [ ! -d /root/.ssh ]; then
    mkdir -p /root/.ssh
    chmod 700 /root/.ssh
fi
# Fetch public key using HTTP
ATTEMPTS=30
FAILED=0
if [ ! -f /root/.ssh/authorized_keys ]; then
    wget http://169.254.169.254/latest/meta-data/public-keys/0/openssh-key -O /tmp/metadata-key -o /var/log/metadata_svc_bugfix.log
    if [ $? -eq 0 ]; then
        cat /tmp/metadata-key >> /root/.ssh/authorized_keys
        chmod 0600 /root/.ssh/authorized_keys
        #restorecon /root/.ssh/authorized_keys
        rm -f /tmp/metadata-key
        echo "Successfully retrieved public key from instance metadata" >> /var/log/metadata_svc_bugfix.log
    fi
fi
