#!/bin/bash

source ${HOME}/stratos_version.conf

CLI_HOME=/home/vagrant/stratos/apache-stratos-cli-${STRATOS_VERSION}

export STRATOS_URL=https://puppet.stratos.com:9443
export STRATOS_USERNAME=admin
export STRATOS_PASSWORD=admin

sudo apt-get install -y expect

image_id=$(glance image-list | grep 'tomcatbase:latest' | cut -d'|' -f2 | tr -d ' ')

if [[ -z $image_id ]]; then 
  echo "Couldn't find image 'tomcatbase:latest'"
  exit 1
fi

tmp_file=$(mktemp)

cp /vagrant/openstack-qemu/example_cartridge.json $tmp_file

sed -i "s/____CHANGE_ME____/$image_id/g" $tmp_file

expect <<EOF
spawn "/usr/bin/java" "-jar" "$CLI_HOME/org.apache.stratos.cli-${STRATOS_VERSION}-Tool.jar" "-username" "admin" "-p" "admin"
expect "stratos>"
send "deploy-partition -p /vagrant/openstack-qemu/example_partition.json\r"
expect "stratos>"
send "deploy-autoscaling-policy -p /vagrant/openstack-qemu/example_autoscale_policy.json\r"
expect "stratos>"
send "deploy-deployment-policy -p /vagrant/openstack-qemu/example_deployment_policy.json\r"
expect "stratos>"
send "deploy-catridge -p $tmp_file\r"
EOF

rm -f $tmp_file
