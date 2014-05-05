#!/bin/bash

# fail on error
set -e

source ${HOME}/stratos_version.conf

CLI_HOME=$(find /home/vagrant/stratos/ -name apache-stratos-cli-*)

export STRATOS_URL=https://puppet.stratos.com:9443
export STRATOS_USERNAME=admin
export STRATOS_PASSWORD=admin

sudo apt-get install -y expect

. ${HOME}/devstack/openrc admin admin

image_id=$(glance image-list | grep 'tomcatbase:latest' | cut -d'|' -f2 | tr -d ' ')

if [[ -z $image_id ]]; then 
  echo "Couldn't find image 'tomcatbase:latest'"
  exit 1
fi

tmp_file=$(mktemp)

cp /vagrant/tests/example_cartridge.json $tmp_file

# replace the placeholder cartridge id with the actual cartridge id
sed -i "s/____CHANGE_ME____/$image_id/g" $tmp_file

cli_jar=$(find $CLI_HOME/org.apache.stratos.cli-*.jar)

# to some provisioning with the stratos CLI
expect <<EOF
spawn "/usr/bin/java" "-jar" "$cli_jar" "-username" "admin" "-p" "admin"
expect "stratos>"
send "deploy-partition -p /vagrant/tests/example_partition.json\r"
expect "stratos>"
send "deploy-autoscaling-policy -p /vagrant/tests/example_autoscale_policy.json\r"
expect "stratos>"
send "deploy-deployment-policy -p /vagrant/tests/example_deployment_policy.json\r"
expect "stratos>"
send "deploy-cartridge -p $tmp_file\r"
expect "stratos>"
send "subscribe-cartridge php php111 -r https://github.com/nirmal070125/phptest.git -dp economyDeployment -ap economyPolicy\r"
expect "stratos>"
send "sync php111\r"
expect "stratos>"
send "exit\r"
EOF

rm -f $tmp_file


function wait_for_ssh_port() {
   local instance_ip=$1

   # install nmap if not already installed
   sudo apt-get install -y nmap

   # wait for the guest OS and ssh server to start
   local count=0
   until [ $(nmap --open -p 22 $instance_ip |grep -c "ssh") -eq 1 ]
   do
     let "count=count+1"
     if [ $count -eq 100 ]
     then
       echo "Retry count failed waiting for ssh on $instance_ip"
       exit 1
     fi
     sleep 20s
     echo "Waiting for ssh port to open on $instance_ip"
   done
}

echo "Sleeping for 3m to give Stratos a chance to start the instance."
sleep 3m

instance_ip=$(nova list | grep "php111" | cut -d'|' -f7 | cut -d'=' -f2 | cut -d',' -f1 | tr -d ' ')


echo "Waiting for SSH port to open on $instance_ip"
wait_for_ssh_port $instance_ip
echo "============================================"
echo "Instance started."
echo "Ssh port open on $instance_ip"
echo "============================================"
