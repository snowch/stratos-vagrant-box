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

# IP Address for this host
IP_ADDR="192.168.56.5"

# Puppet Master IP Address
PUPPET_IP_ADDR="$IP_ADDR"

# The domain name of this server
DOMAINNAME="stratos.com"

# This script will set the hostname to this value
PUPPET_HOSTNAME="puppet.stratos.com"

# source and maven versions
source ${HOME}/stratos_version.conf

# Stratos folders
STRATOS_PACK_PATH="${HOME}/stratos-packs"
STRATOS_SETUP_PATH="${HOME}/stratos-installer"
STRATOS_SOURCE_PATH="${HOME}/stratos-source"
STRATOS_PATH="${HOME}/stratos"

# ActiveMQ 5.9.1 location.  Note: only 5.9.1 is supported by this script
ACTIVEMQ_URL="http://archive.apache.org/dist/activemq/5.9.1/apache-activemq-5.9.1-bin.tar.gz"

# MySQL download location.
MYSQLJ_URL="http://repo1.maven.org/maven2/mysql/mysql-connector-java/5.1.29/mysql-connector-java-5.1.29.jar"

# Tomcat download location.
TOMCAT_URL="http://archive.apache.org/dist/tomcat/tomcat-7/v7.0.52/bin/apache-tomcat-7.0.52.tar.gz"

# Hawtbuf download location.
HAWTBUF_URL="http://repo1.maven.org/maven2/org/fusesource/hawtbuf/hawtbuf/1.2/hawtbuf-1.2.jar"

MVN_SETTINGS="-s /vagrant/maven-settings.xml"

XRDP_URL="https://github.com/snowch/X11RDP-o-Matic/releases/download/0.1/xrdp_0.9.0.master-1_amd64.deb"
XRDP_SHA1="67f4558751a94b4bd787602530bd158ec6b3f3e7"

X11RDP_URL="https://github.com/snowch/X11RDP-o-Matic/releases/download/0.1/x11rdp_0.9.0.master-1_amd64.deb"
X11RDP_SHA1="2e049de90932fa5f5e35157728f870acedb62e65"




########################################################
# You should not need to change anything below this line
########################################################

# Don't allow uninitialised variables
# set -u

# propagate ERR
set -o errtrace


if [ "$(arch)" == "x86_64" ]
then
   JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64/
else
   JAVA_HOME=/usr/lib/jvm/java-7-openjdk-i386/
fi

grep -q '^export JAVA_HOME' ~/.profile || echo "export JAVA_HOME=$JAVA_HOME" >> ~/.profile
. ~/.profile


progname=$0
progdir=$(dirname $progname)
progdir=$(cd $progdir && pwd -P || echo $progdir)
progarg=''

function finish {
   echo "\n\nReceived SIGINT. Exiting..."
   exit
}
trap finish SIGINT

error() {
  echo "Error running ${progname} around line $1"
  exit 1
}
trap 'error ${LINENO}' ERR

function main() {
  while getopts 'fwcbmpndskth' flag; do
    progarg=${flag}
    case "${flag}" in
      f) initial_setup ; exit $? ;;
      w) downloads; exit $? ;;
      c) checkout; exit $? ;;
      b) maven_clean_install; exit $? ;;
      n) installer; exit $? ;;
      d) development_environment; exit $? ;;
      s) start_servers; exit $? ;;
      k) kill_servers; exit $? ;;
      t) servers_status; exit $? ;;
      h) usage ; exit $? ;;
      \?) usage ; exit $? ;;
      *) usage ; exit $? ;;
    esac
  done
  usage
}

function usage () {
   cat <<EOF
Usage: $progname -[f|w|c|b|n|d|h]

Where:
       ----------------------------------------------------------------
       IMPORTANT: 
       The first time you run this script must be with the command '-f'

       You must also configure the iaas.conf file in the ${HOME}
       folder with the details of your IaaS.  For more information on 
       EC2 configuration, see this thread: http://tinyurl.com/p48euoj
       ----------------------------------------------------------------

    -f perform a complete setup of the stratos runtime environment

       This command is the same as running:
       $progname -w && $progname -c && $progname -b && $progname -n

    -w Download pre-requisite files such as MYSQLJ


    -c Checkout Stratos 'master' code.  
       Each time you run this command, this script will do a 'git pull'

    -b Builds Stratos.  Equivalent to running: 'mvn clean install'
       You will probably want to re-run this after you modify or pull new source 

    -n Install Stratos and CLI (and startup Stratos).
       You will probably want to re-run this after you re-setup Puppet.
       Use 'tail -f ${HOME}/stratos-log/stratos-setup.log' to watch output.

       When you see the 'Servers Started' message, you should be able to connect
       with your browser to:

       Hostname: https://$IP_ADDR:9443
       Username: admin
       Password: admin

    -d Setup a development environment with ubuntu desktop and eclipse.
       This Command is only intented to be run on a vagrant environment.

       You can connect using rdesktop or Windows Remote Desktop Client.  
       Hostname: $IP_ADDR
       Username: vagrant
       Password: vagrant

    -s Start activemq and stratos
       The servers will take some time to startup. Check status with '-t'
       
    -k Kill activemq and stratos
       Stratos takes some time to shutdown. Check status with '-t'

    -t Show activemq and stratos server status.

    -h show this help message

All commands can be re-run as often as required.
EOF
   exit 0
}

function downloads () {

  prerequisites # setup pre-requisites

  echo -e "\e[32mDownload prerequisite software\e[39m"

  [ -d $STRATOS_PACK_PATH ] || mkdir $STRATOS_PACK_PATH

  if [ ! -e $STRATOS_PACK_PATH/$(basename $MYSQLJ_URL) ]
  then
     echo "Downloading $MYSQLJ_URL"
     wget -N -nv -P $STRATOS_PACK_PATH $MYSQLJ_URL
  fi
}

function fix_git_tls_bug() {

  pushd $PWD

  if [ -d ~/git-openssl ]
  then
    # we have already setup git
    return
  fi
  sudo apt-get update
  sudo apt-get install -y build-essential fakeroot dpkg-dev
  mkdir ~/git-openssl
  cd ~/git-openssl
  sudo apt-get source -y git
  sudo apt-get build-dep -y git
  sudo apt-get install -y libcurl4-openssl-dev
  sudo dpkg-source -x git_1.7.9.5-1.dsc
  cd git-1.7.9.5
  sudo sed -i 's/libcurl4-gnutls-dev/libcurl4-openssl-dev/g' debian/control
  sudo sed -i '/^TEST =test$/d' debian/rules
  sudo dpkg-buildpackage -rfakeroot -b
  sudo dpkg -i ../git_1.7.9.5-1_i386.deb

  popd
}

function prerequisites() {

  echo -e "\e[32mInstall prerequisite software\e[39m"
  sudo apt-get update
  sudo DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade
  sudo apt-get install -y --no-install-recommends git maven openjdk-7-jdk curl

  curl -s https://get.docker.io/ubuntu/ | sudo sh
  sudo ln -sf /usr/bin/docker.io /usr/local/bin/docker
  sudo sed -i '$acomplete -F _docker docker' /etc/bash_completion.d/docker

  if [ "$(arch)" != "x86_64" ]
  then
    fix_git_tls_bug
  fi

  if [ "$(arch)" == "x86_64" ]
  then
    grep '^export MAVEN_OPTS' .profile || echo 'export MAVEN_OPTS="-Xmx2048m -XX:MaxPermSize=512m -XX:ReservedCodeCacheSize=256m -Xdebug -Xrunjdwp:transport=dt_socket,address=8888,server=y,suspend=n"' >> .profile
  else
    grep '^export MAVEN_OPTS' .profile || echo 'export MAVEN_OPTS="-Xmx1024m -XX:MaxPermSize=512m -XX:ReservedCodeCacheSize=256m -Xdebug -Xrunjdwp:transport=dt_socket,address=8888,server=y,suspend=n"' >> .profile
  fi
  . .profile
}

function installer() {

  echo -e "\e[32mRunning Stratos Installer\e[39m"

  pushd $PWD

  rm -rf $HOME/cli
  mkdir -p $HOME/cli 

  # extract cli zip file
  cli_file=$(find $STRATOS_SOURCE_PATH/products/stratos-cli/distribution/target/apache-stratos-cli-*.zip)
  unzip $cli_file -d $HOME/cli
  STRATOS_CLI_HOME=$HOME/cli/$(basename $cli_file)
 
  # TODO use sed line replacement
  grep -q '^export STRATOS_CLI_HOME' ~/.profile || echo "export STRATOS_CLI_HOME=$STRATOS_CLI_HOME" >> ~/.profile
  . ~/.profile
  export STRATOS_CLI_HOME

  cd $STRATOS_SOURCE_PATH/tools/stratos-docker-images
  ./build-all.sh

  popd
}

function start_servers() {

  echo Stopping Stratos docker images
  kill_servers

  MB_ID=$(sudo docker run -p 61616 -d apachestratos/activemq); sleep 2s;
  MB_IP_ADDR=$(sudo docker inspect --format '{{ .NetworkSettings.Gateway }}' $MB_ID)
  MB_PORT=$(sudo docker port $MB_ID 61616 | awk -F':' '{ print $2 }')

  USERSTORE_ID=$(sudo docker run -d -p 3306 -e MYSQL_ROOT_PASSWORD=password apachestratos/mysql); sleep 2s;
  USERSTORE_IP_ADDR=$(sudo docker inspect --format '{{ .NetworkSettings.Gateway }}' $USERSTORE_ID)
  USERSTORE_PORT=$(sudo docker port $USERSTORE_ID 3306 | awk -F':' '{ print $2 }')

  unset docker_env

  # Database Settings
  docker_env+=(-e "USERSTORE_DB_HOSTNAME=${USERSTORE_IP_ADDR}")
  docker_env+=(-e "USERSTORE_DB_PORT=${USERSTORE_PORT}")
  docker_env+=(-e "USERSTORE_DB_SCHEMA=USERSTORE_DB_SCHEMA")
  docker_env+=(-e "USERSTORE_DB_USER=root")
  docker_env+=(-e "USERSTORE_DB_PASS=password")

  # Puppet Setings
  docker_env+=(-e "PUPPET_IP=${PUPPET_IP_ADDR}")
  docker_env+=(-e "PUPPET_HOSTNAME=${PUPPET_HOSTNAME}")
  docker_env+=(-e "PUPPET_ENVIRONMENT=none")

  # MB Settings
  docker_env+=(-e "MB_HOSTNAME=${MB_IP_ADDR}")
  docker_env+=(-e "MB_PORT=${MB_PORT}")

  # read variables from iaas.conf, escaping colons to prevent later sed statements throwing an error
  source <(sed 's/:/\\\\:/g' ${HOME}/iaas.conf)
    
  # IAAS Settings
  docker_env+=(-e "EC2_ENABLED=$ec2_provider_enabled")
  docker_env+=(-e "EC2_IDENTITY=$ec2_identity")
  docker_env+=(-e "EC2_CREDENTIAL=$ec2_credential")
  docker_env+=(-e "EC2_OWNER_ID=$ec2_owner_id")
  docker_env+=(-e "EC2_AVAILABILITY_ZONE=$ec2_availability_zone")
  docker_env+=(-e "EC2_SECURITY_GROUPS=$ec2_security_groups")
  docker_env+=(-e "EC2_KEYPAIR=$ec2_keypair_name")

  # Openstack
  docker_env+=(-e "OPENSTACK_ENABLED=$openstack_provider_enabled")
  docker_env+=(-e "OPENSTACK_IDENTITY=$openstack_identity")
  docker_env+=(-e "OPENSTACK_CREDENTIAL=$openstack_credential")
  docker_env+=(-e "OPENSTACK_ENDPOINT=$openstack_jclouds_endpoint")
  #docker_env+=(-e "OPENSTACK_KEYPAIR_NAME=$openstack_keypair_name")
  #docker_env+=(-e "OPENSTACK_SECURITY_GROUPS=$openstack_security_groups")

  # vCloud
  docker_env+=(-e "VCLOUD_ENABLED=$vcloud_provider_enabled")
  docker_env+=(-e "VCLOUD_IDENTITY=$vcloud_identity")
  docker_env+=(-e "VCLOUD_CREDENTIAL=$vcloud_credential")
  docker_env+=(-e "VCLOUD_JCLOUDS_ENDPOINT=$vcloud_jclouds_endpoint")

  # Stratos Settings [profile=default|cc|as|sm]
  docker_env+=(-e "STRATOS_PROFILE=default")

  # Start Stratos container as daemon
  container_id=$(sudo docker run -d "${docker_env[@]}" -p 9443:9443 apachestratos/stratos)  

  echo -n Starting Stratos docker images 
  timer=0
  success=1
  while [[ $(curl -s --insecure -3 -o /dev/null -I -w "%{http_code}" https://localhost:9443/console/login) != 200 ]]; do 
    echo -n .
    sleep 10s
    timer=$((timer + 10))
    if (( $timer > 600 )); then
      printf "\nTime out waiting for Stratos to start\n"
      success=0
      break
    fi
  done
  if [[ $success = 1 ]]; then
    printf "\nStratos docker images have started\n"
  fi
 
}

function kill_servers() {

  stratos_container_ids=$(sudo docker ps -a | awk '{print $2, $1}' | grep '^apachestratos' | awk '{print $2}')

  if [[ -n $stratos_container_ids ]]; then
    sudo docker stop $stratos_container_ids
    sudo docker rm $stratos_container_ids
  fi
}

function servers_status() {

  # TODO
  sleep 1

}

function development_environment() {

   pushd $PWD

   echo -e "\e[32mSetting up development environment.\e[39m"

   sudo apt-get update
   sudo apt-get upgrade -y
   sudo apt-get install -y xubuntu-desktop xfce4 eclipse-jdt xvfb firefox gnome-terminal sysv-rc-conf

   sudo ufw disable

   cd $HOME

   sha1=$(sha1sum  $STRATOS_PACK_PATH/$(basename $X11RDP_URL) | awk '{ print $1 }')

   if [[ $sha1 != $X11RDP_SHA1 ]]; then
     rm -f $STRATOS_PACK_PATH/$(basename $X11RDP_URL)
     wget -N -nv -P $STRATOS_PACK_PATH $X11RDP_URL
   fi
   sudo dpkg -i $STRATOS_PACK_PATH/$(basename $X11RDP_URL)

   sha1=$(sha1sum  $STRATOS_PACK_PATH/$(basename $XRDP_URL) | awk '{ print $1 }')

   if [[ $sha1 != $XRDP_SHA1 ]]; then
     rm -f $STRATOS_PACK_PATH/$(basename $XRDP_URL)
     wget -N -nv -P $STRATOS_PACK_PATH $XRDP_URL
   fi
   sudo dpkg -i $STRATOS_PACK_PATH/$(basename $XRDP_URL)

   echo xfce4-session > ~/.xsession
   echo 'mode: off' > ~/.xscreensaver

   sudo update-rc.d xrdp defaults
   sudo /etc/init.d/xrdp start

   # switch off update manager popup
   # FIXME: this doesn't seem to work
   sudo sed -i 's/NoDisplay=true/NoDisplay=false/g' /etc/xdg/autostart/*.desktop

   cd $STRATOS_SOURCE_PATH
   echo "Running 'mvn eclipse:eclipse'"
   mvn $MVN_SETTINGS -q eclipse:eclipse

   # import projects
   echo "Downloading eclipse import util"
   sudo wget -N -nv -P /usr/share/eclipse/dropins/ \
      https://github.com/snowch/test.myapp/raw/master/test.myapp_1.0.0.jar

   # get all the directories that can be imported into eclipse and append them
   # with '-import'

   if [ -e ${HOME}/workspace ]
   then
      IMPORTS='' # importing fails if workspace already has imported projects 
   else
      IMPORTS=$(find $STRATOS_SOURCE_PATH -type f -name .project)
   fi

   IMPORT_ERRORS=""

   # Although it is possible to import multiple directories with one 
   # invocation of the test.myapp.App, this fails if one of the imports
   # was not successful.  Using a for loop is slower, but more robust
   trap - ERR

   for item in ${IMPORTS[*]};
   do
      IMPORT="$(dirname $item)/"

      # perform the import 
      eclipse -nosplash \
         -application test.myapp.App \
         -data ${HOME}/workspace \
         -import $IMPORT
      if [ $? != 0 ]
      then
        IMPORT_ERRORS="${IMPORT_ERRORS}\n${IMPORT}"
      fi
   done

   # turn error handling back on
   trap 'error ${LINENO}' ERR

   if [ -z "$IMPORT_ERRORS" ]
   then
      echo -e "\e[31mImport Errors:\n\n\e[39m"
      echo -e "\e[31m$IMPORT_ERRORS\e[39m"
   fi

   mvn $MVN_SETTINGS -Declipse.workspace=${HOME}/workspace/ eclipse:configure-workspace

   popd

   # start the servers again
   start_servers
}

function checkout() {

  echo -e "\e[32mChecking out.\e[39m"

  pushd $PWD

  if [ ! -d $STRATOS_SOURCE_PATH ]
  then
     git clone https://git-wip-us.apache.org/repos/asf/stratos.git $STRATOS_SOURCE_PATH
  else
     cd $STRATOS_SOURCE_PATH
     git checkout master
     git pull
  fi

  cd $STRATOS_SOURCE_PATH
  git checkout ${STRATOS_SRC_VERSION}

  popd
}

function maven_clean_install () {
   
   echo -e "\e[32mRunning 'mvn clean install'.\e[39m"
   
   pushd $PWD
   cd $STRATOS_SOURCE_PATH
   
   mvn $MVN_SETTINGS clean install -DskipTests
   popd
}

function force_clean () {
   
   pushd $PWD
   echo -e "\e[32mIMPORTANT\e[39m"
   echo "Reset your environment?  This will lose any changes you have made."
   echo
   read -p "Please close eclipse, stop any maven jobs and press [Enter] key to continue."
   
   cd $STRATOS_SOURCE_PATH
   mvn $MVN_SETTINGS clean
   
   rm -rf ${HOME}/workspace-stratos
   
   rm -rf ${HOME}/.m2
   
   popd
}

function initial_setup() {
   
   echo -e "\e[32mPerforming initial setup.\e[39m"
   downloads   
   prerequisites
   checkout
   maven_clean_install
   installer
}

main "$@"
