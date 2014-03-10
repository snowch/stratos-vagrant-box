#!/bin/bash
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

set -e

# TODO the getops loop to check this has been set as an environment
# variable in .profile. If not, the value to be passed in as an argument
# to this script

CLOUDSTACK_VERSION="24dcf2948c2d4cdd98fcda0f766d82f40eee8be1"

progname=$0
progdir=$(dirname $progname)
progdir=$(cd $progdir && pwd -P || echo $progdir)
progarg=''

function finish {
   echo "\n\nReceived SIGINT. Exiting..."
   exit
}

trap finish SIGINT

function usage () {
   cat <<EOF
Usage: $progname -[i|c|r|p|d]
where:
    -i checkout and build
    -c clean cloudstack database
    -r run cloudstack
    -p provision cloudstack
    -d cloudstack development environment
EOF
   exit 0
}


function base_setup () {

  pushd $PWD

  set +e
  # set dom0 max memory to 2Gb
  grep 'GRUB_CMDLINE_XEN="dom0_mem=400M,max:2048M dom0_max_vcpus=1"' /etc/default/grub
  if [ $? != 0 ]
  then
     echo
     echo -e "\e[32mIMPORTANT\e[39m"
     echo "Updating XEN grub command line and rebooting."
     echo "Run '${progname} -${progarg}' after the reboot to continue the setup."
     echo
     read -p "Press [Enter] key to continue..."
     echo
     sudo sed -i -e 's/^GRUB_CMDLINE_XEN.*$/GRUB_CMDLINE_XEN="dom0_mem=400M,max:2048M dom0_max_vcpus=1"/g' /etc/default/grub
     sudo update-grub2
     sudo reboot
     # stop script from running further while rebooting
     sleep 60
  fi
  set -e

  [ -d /home/vagrant/Downloads ] || mkdir /home/vagrant/Downloads

  chown -R vagrant /home/vagrant/Downloads

  if [ ! -e /home/vagrant/Downloads/apache-tomcat-6.0.33.tar.gz ]
  then
     wget -c -P /home/vagrant/Downloads \
        http://archive.apache.org/dist/tomcat/tomcat-6/v6.0.33/bin/apache-tomcat-6.0.33.tar.gz

     tar xzf /home/vagrant/Downloads/apache-tomcat-6.0.33.tar.gz -C /home/vagrant
  fi

  # only update ~/.profile if it doesn't have required settings
  cd /home/vagrant

  # the rest of the profile settings are for maven
  grep '^CATALINA_HOME' .profile || echo 'export CATALINA_HOME=~/apache-tomcat-6.0.33' >> .profile

  grep '^CATALINA_BASE' .profile || echo 'export CATALINA_BASE=~/apache-tomcat-6.0.33' >> .profile

  if [ "$(arch)" == "x86_64" ]
  then
    grep '^JAVA_HOME' .profile || echo 'export JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64' >> .profile
  else
    grep '^JAVA_HOME' .profile || echo 'export JAVA_HOME=/usr/lib/jvm/java-7-openjdk-i386' >> .profile
  fi

  grep '^MAVEN_OPTS' .profile || echo 'export MAVEN_OPTS="-Xmx1024m -XX:MaxPermSize=500m -Xdebug -Xrunjdwp:transport=dt_socket,address=8787,server=y,suspend=n"' >> .profile

  . .profile

  sudo /etc/init.d/mysql start

  sudo apt-get install -y uuid-runtime genisoimage python-setuptools python-dev git ca-certificates maven openjdk-7-jdk python-pip expect

  # maven builds can fail with openjdk-6
  sudo apt-get remove -y openjdk-6-jre-headless

  sudo ln -sf /usr/bin/genisoimage /usr/bin/mkisofs
  
  popd
}

function checkout_cloudstack() {

  if [ ! -e /home/vagrant/Downloads/vhd-util ]
  then
     # get the vhd-util - we will need this later
     wget -c -P /home/vagrant/Downloads \
       http://download.cloud.com.s3.amazonaws.com/tools/vhd-util
  fi

  pushd $PWD
  cd /home/vagrant

  if [ ! -d /home/vagrant/cloudstack ]
  then
     git clone https://git-wip-us.apache.org/repos/asf/cloudstack.git
  else
     cd /home/vagrant/cloudstack
     git checkout master
     git pull
  fi

  # remove vhd-util to prevent git complaining about unstaged changes
  rm -f /home/vagrant/cloudstack/scripts/vm/hypervisor/xenserver/vhd-util

  cd /home/vagrant/cloudstack
  git checkout ${CLOUDSTACK_VERSION}

  cp /home/vagrant/Downloads/vhd-util \
     /home/vagrant/cloudstack/scripts/vm/hypervisor/xenserver/vhd-util

  chmod +x /home/vagrant/cloudstack/scripts/vm/hypervisor/xenserver/vhd-util
  
  sed -i -e 's/^reboot -f$/#reboot -f/g' \
      /home/vagrant/cloudstack/scripts/vm/hypervisor/xenserver/xenheartbeat.sh

  popd
}

function clean_cloudstack_db () {
   pushd $PWD
   cd /home/vagrant/cloudstack
   mvn -P developer -pl developer,tools/devcloud -Ddeploydb
   # change host from 192.168.56.1 to .10 for running cloudstack on devcloud
   sudo mysql -e "update configuration set value = '192.168.56.10' where name = 'host';" cloud
   popd
}

function maven_clean_install () {
   pushd $PWD
   cd /home/vagrant/cloudstack
   mvn clean install -P developer,systemvm
   
   MARVIN=$(ls -1 /home/vagrant/cloudstack/tools/marvin/dist/Marvin-*.tar.gz)
   sudo pip install $MARVIN
   popd
}

function run_cloudstack () {
   pushd $PWD
   cd /home/vagrant/cloudstack
   mvn -pl :cloud-client-ui jetty:run
   popd
}

function provision_cloudstack () {
   pushd $PWD
   if [ ! -e $progdir/devcloud.cfg ]
   then
      wget https://github.com/imduffy15/devcloud/raw/v0.2/devcloud.cfg
   fi
   cd /home/vagrant/cloudstack/tools/devcloud
   python ../marvin/marvin/deployDataCenter.py -i $progdir/devcloud.cfg
   popd
}

function development_environment () {
   pushd $PWD
   sudo apt-get install -y --no-install-recommends task-lxde-desktop eclipse-jdt xrdp
   cd /home/vagrant/cloudstack
   mvn eclipse:eclipse
   # import projects
   sudo wget -c -P /usr/share/eclipse/dropins/ \
      https://github.com/snowch/test.myapp/raw/master/test.myapp_1.0.0.jar
      
   # get all the directories that can be imported into eclipse and append them
   # with '-import'

   IMPORTS=$(find /home/vagrant/cloudstack/ -type f -name .project)

   # Although it is possible to import multiple directories with one 
   # invocation of the test.myapp.App, this fails if one of the imports
   # was not successful.  Using a for loop is slower, but more robust
   for item in ${IMPORTS[*]}; 
   do
      IMPORT="$(dirname $item)/"
  
      # perform the import
      eclipse -nosplash \
         -application test.myapp.App \
         -data /home/vagrant/workspace \
         -import $IMPORT
   done
   mvn -Declipse.workspace=/home/vagrant/workspace/ eclipse:configure-workspace
   popd
}


function initial_setup() {
   base_setup
   checkout_cloudstack
   maven_clean_install
   clean_cloudstack_db
   # run jetty, when jetty has started provision cloudstack
expect <<EOF
   cd /home/vagrant/cloudstack
   set timeout 12000
   match_max 1000000
  
   set success_string "*Started Jetty Server*"

   spawn "/home/vagrant/cloudstack_dev.sh" "-r"
   expect {
     -re "(\[^\r]*\)\r\n" 
     {
       set current_line \$expect_out(buffer)

       if { [ string match "\$success_string" "\$current_line" ] } {
          puts "exiting with matched string \$current_line"
          flush stdout
          send "/home/vagrant/cloudstack_dev.sh -p"
       } else { 
          puts "discarding \$current_line"
          exp_continue 
       }
     }
     eof { puts "eof"; exit 1; }
     timeout { puts "timeout"; exit 1; }
   }
EOF
   development_environment
}

while getopts 'icrpd' flag; do
  progarg=${flag}
  case "${flag}" in
    i) initial_setup ; exit $? ;;
    c) clean_cloudstack_db ; exit $? ;;
    r) run_cloudstack ; exit $? ;;
    p) provision_cloudstack ; exit $? ;;
    d) development_environment ; exit $? ;;
    h) usage ; exit $? ;;
    \?) usage ; exit $? ;;
    *) usage ; exit $? ;;
  esac
done

usage
