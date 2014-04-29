#!/bin/bash

CLI_HOME=/home/vagrant/stratos/apache-stratos-cli-4.0.0-incubating

export STRATOS_URL=https://puppet.stratos.com:9443
export STRATOS_USERNAME=admin
export STRATOS_PASSWORD=admin



sudo apt-get install -y expect

expect <<EOF
  
spawn "/usr/bin/java" "-jar" "$CLI_HOME/org.apache.stratos.cli-4.0.0-incubating-Tool.jar" "-username" "admin" "-p" "admin"
expect "stratos>"
send "deploy-partition -p /vagrant/openstack-qemu/example_partition.json\r"
expect "stratos>"
send "deploy-autoscaling-policy -p /vagrant/openstack-qemu/example_autoscale_policy.json\r"
expect "stratos>"
send "deploy-deployment-policy -p /vagrant/openstack-qemu/example_deployment_policy.json\r"
expect "stratos>"
send "deploy-catridge -p /vagrant/openstack-qemu/example_cartridge.json\r"
EOF
