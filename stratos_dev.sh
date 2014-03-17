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


STRATOS_VERSION="4.0.0-incubating-m7"
STRATOS_PACK_PATH="/home/vagrant/stratos-packs"
STRATOS_SETUP_PATH="/home/vagrant/stratos-installer"
STRATOS_SOURCE_PATH="/home/vagrant/incubator-stratos"
STRATOS_PATH="/home/vagrant/stratos"
WSO2_CEP_FILE="wso2cep-3.0.0.zip"
WSO2_MB_FILE="wso2mb-2.1.0.zip"
MYSQLJ_FILE="mysql-connector-java-5.1.29.jar"
IP_ADDR="192.168.56.10"

progname=$0
progdir=$(dirname $progname)
progdir=$(cd $progdir && pwd -P || echo $progdir)
progarg=''

export MAVEN_OPTS="-Xmx1024m -XX:MaxPermSize=500m -Xdebug -Xrunjdwp:transport=dt_socket,address=8888,server=y,suspend=n"

function finish {
   echo "\n\nReceived SIGINT. Exiting..."
   exit
}

trap finish SIGINT

function main() {
  while getopts 'icrpdf' flag; do
    progarg=${flag}
    case "${flag}" in
      i) initial_setup ; exit $? ;;
      h) usage ; exit $? ;;
      \?) usage ; exit $? ;;
      *) usage ; exit $? ;;
    esac
  done
  usage
}

function usage () {
   cat <<EOF
Usage: $progname -[i|c|r|p|d|f]
where:
    -i checkout and build
EOF
   exit 0
}

function downloads () {

  echo -e "\e[32mDownload prerequisite software\e[39m"

  [ -d $STRATOS_PACK_PATH ] || mkdir $STRATOS_PACK_PATH

  if [ ! -e $STRATOS_PACK_PATH/$WSO2_CEP_FILE ]
  then
     wget -q -P $STRATOS_PACK_PATH http://people.apache.org/~chsnow/$WSO2_CEP_FILE
  fi
  
  if [ ! -e $STRATOS_PACK_PATH/$WSO2_MB_FILE ]
  then
     wget -q -P $STRATOS_PACK_PATH http://people.apache.org/~chsnow/$WSO2_MB_FILE
  fi

  if [ ! -e $STRATOS_PACK_PATH/$MYSQLJ_FILE ]
  then
     wget -q -P $STRATOS_PACK_PATH http://repo1.maven.org/maven2/mysql/mysql-connector-java/5.1.29/$MYSQLJ_FILE
  fi
}

function prerequisites() {

  echo -e "\e[32mInstall prerequisite software\e[39m"
  sudo apt-get update
  sudo apt-get install -y --no-install-recommends git maven openjdk-7-jdk

}

function puppet_setup() {

  pushd $PWD
  cd /home/vagrant

  if [ ! -d puppetinstall ]
  then
    git clone https://github.com/thilinapiy/puppetinstall
    cd puppetinstall
    echo '' | sudo ./puppetinstall -m -d stratos.com

    sudo cp -R $STRATOS_SOURCE_PATH/tools/puppet/manifests/* /etc/puppet/manifests/
    sudo cp -R $STRATOS_SOURCE_PATH/tools/puppet/modules/* /etc/puppet/modules/
  fi
  popd 

}

function installer() {
  pushd $PWD
  cp -rpf $STRATOS_SOURCE_PATH/tools/stratos-installer $STRATOS_SETUP_PATH
  mv $STRATOS_SOURCE_PATH/products/stratos-manager/modules/distribution/target/apache-stratos-manager-*.zip $STRATOS_PACK_PATH/
  mv $STRATOS_SOURCE_PATH/products/cloud-controller/modules/distribution/target/apache-stratos-cc-*.zip $STRATOS_PACK_PATH/
  mv $STRATOS_SOURCE_PATH/products/autoscaler/modules/distribution/target/apache-stratos-autoscaler-*.zip $STRATOS_PACK_PATH/
  mv $STRATOS_SOURCE_PATH/extensions/cep/stratos-cep-extension/target/org.apache.stratos.cep.extension-*.jar $STRATOS_PACK_PATH

  sed -i "s:^export setup_path=.*:export setup_path=$STRATOS_SETUP_PATH:g" $STRATOS_SETUP_PATH/conf/setup.conf
  sed -i "s:^export stratos_pack_path=.*:export stratos_pack_path=$STRATOS_PACK_PATH:g" $STRATOS_SETUP_PATH/conf/setup.conf
  sed -i "s:^export stratos_path=.*:export stratos_path=$STRATOS_PATH:g" $STRATOS_SETUP_PATH/conf/setup.conf
  sed -i "s:^export JAVA_HOME=.*:export JAVA_HOME=$JAVA_HOME:g" $STRATOS_SETUP_PATH/conf/setup.conf
  sed -i "s:^export host_user=.*:export host_user=vagrant:g" $STRATOS_SETUP_PATH/conf/setup.conf
  sed -i "s:^export mb_ip=.*:export mb_ip=$IP_ADDR:g" $STRATOS_SETUP_PATH/conf/setup.conf
  sed -i "s:^export cep_ip=.*:export cep_ip=$IP_ADDR:g" $STRATOS_SETUP_PATH/conf/setup.conf
  sed -i "s:^export cc_ip=.*:export cc_ip=$IP_ADDR:g" $STRATOS_SETUP_PATH/conf/setup.conf
  sed -i "s:^export as_ip=.*:export as_ip=$IP_ADDR:g" $STRATOS_SETUP_PATH/conf/setup.conf
  sed -i "s:^export sm_ip=.*:export sm_ip=$IP_ADDR:g" $STRATOS_SETUP_PATH/conf/setup.conf
  sed -i "s:^export sm_ip=.*:export sm_ip=$IP_ADDR:g" $STRATOS_SETUP_PATH/conf/setup.conf
  sed -i "s:^export puppet_ip=.*:export puppet_ip=$IP_ADDR:g" $STRATOS_SETUP_PATH/conf/setup.conf
  sed -i "s:^export puppet_hostname=.*:export puppet_hostname=devcloud:g" $STRATOS_SETUP_PATH/conf/setup.conf
  sed -i "s:^export puppet_environment=.*:export puppet_environment=XXXXXXXXXXXXXXXXX:g" $STRATOS_SETUP_PATH/conf/setup.conf
  # TODO finish this section

  popd
}

function checkout() {

  echo -e "\e[32mChecking out.\e[39m"

  pushd $PWD

  if [ ! -d $STRATOS_SOURCE_PATH ]
  then
     git clone https://git-wip-us.apache.org/repos/asf/incubator-stratos.git $STRATOS_SOURCE_PATH
  else
     cd $STRATOS_SOURCE_PATH
     git checkout master
     git pull
  fi

  cd $STRATOS_SOURCE_PATH
  git checkout ${STRATOS_VERSION}

  popd
}

function maven_clean_install () {
   
   echo -e "\e[32mRunning 'mvn clean install'.\e[39m"
   
   pushd $PWD
   cd /home/vagrant/incubator-stratos
   mvn clean install
   popd
}

function force_clean () {
   
   pushd $PWD
   echo -e "\e[32mIMPORTANT\e[39m"
   echo "Reset your environment?  This will lose any changes you have made."
   echo
   read -p "Please close eclipse, stop any maven jobs and press [Enter] key to continue..."
   
   cd /home/vagrant/incubator-stratos
   mvn clean
   
   rm -rf /home/vagrant/workspace-stratos
   
   rm -rf /home/vagrant/.m2
   
   popd
}

function initial_setup() {
   
   echo -e "\e[32mPerforming initial setup.\e[39m"
   downloads   
   prerequisites
   checkout
   puppet_setup # has a dependency on stratos checkout
   maven_clean_install
}

main "$@"
