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


STRATOS_VERSION="master"
STRATOS_PACK_PATH="/home/vagrant/stratos-packs"
STRATOS_SETUP_PATH="/home/vagrant/stratos-installer"
STRATOS_SOURCE_PATH="/home/vagrant/incubator-stratos"
STRATOS_PATH="/home/vagrant/stratos"
WSO2_CEP_URL="http://people.apache.org/~chsnow"
WSO2_CEP_FILE="wso2cep-3.0.0.zip"
WSO2_MB_URL="http://people.apache.org/~chsnow"
WSO2_MB_FILE="wso2mb-2.1.0.zip"
MYSQLJ_URL="http://repo1.maven.org/maven2/mysql/mysql-connector-java/5.1.29"
MYSQLJ_FILE="mysql-connector-java-5.1.29.jar"
ANDES_CLIENT_JAR_URL="http://maven.wso2.org/nexus/content/groups/wso2-public/org/wso2/andes/wso2/andes-client/0.13.wso2v8/"
ANDES_CLIENT_JAR_FILE="andes-client-0.13.wso2v8.jar"
IP_ADDR="192.168.56.10"
MB_PORT=5672
CEP_PORT=7611

progname=$0
progdir=$(dirname $progname)
progdir=$(cd $progdir && pwd -P || echo $progdir)
progarg=''


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
     wget -q -P $STRATOS_PACK_PATH $WSO2_CEP_URL/$WSO2_CEP_FILE
  fi
  
  if [ ! -e $STRATOS_PACK_PATH/$WSO2_MB_FILE ]
  then
     wget -q -P $STRATOS_PACK_PATH $WSO2_MB_URL/$WSO2_MB_FILE
  fi

  if [ ! -e $STRATOS_PACK_PATH/$MYSQLJ_FILE ]
  then
     wget -q -P $STRATOS_PACK_PATH $MYSQLJ_URL/$MYSQLJ_FILE
  fi

  if [ ! -e $STRATOS_PACK_PATH/$ANDES_CLIENT_JAR_FILE ]
  then
     wget -q -P $STRATOS_PACK_PATH $ANDES_CLIENT_JAR_URL/$ANDES_CLIENT_JAR_FILE
  fi
}

function prerequisites() {

  echo -e "\e[32mInstall prerequisite software\e[39m"
  sudo apt-get update
  sudo apt-get install -y --no-install-recommends git maven openjdk-7-jdk

  grep '^export MAVEN_OPTS' .profile || echo 'export MAVEN_OPTS="-Xmx1024m -XX:MaxPermSize=500m -Xdebug -Xrunjdwp:transport=dt_socket,address=8888,server=y,suspend=n"' >> .profile
  . .profile
}

function puppet_setup() {

  pushd $PWD
  cd /home/vagrant

  if [ ! -d puppetinstall ]
  then
    git clone https://github.com/thilinapiy/puppetinstall
    cd puppetinstall
    echo '' | sudo ./puppetinstall -m -d stratos.com

    [ -d /etc/puppet/modules/agent/files ] || sudo mkdir -p /etc/puppet/modules/agent/files

    sudo cp -R $STRATOS_SOURCE_PATH/tools/puppet3/manifests/* /etc/puppet/manifests/
    sudo cp -R $STRATOS_SOURCE_PATH/tools/puppet3/modules/* /etc/puppet/modules/
    sudo cp -R $STRATOS_SOURCE_PATH/products/cartridge-agent/modules/distribution/target/apache-stratos-cartridge-agent-*-bin.zip /etc/puppet/modules/agent/files
    sudo cp -R $STRATOS_SOURCE_PATH/products/load-balancer/modules/distribution/target/apache-stratos-load-balancer-*.zip /etc/puppet/modules/agent/files

    sudo sh -c 'echo "*.stratos.com" > /etc/puppet/autosign.conf'

    # TODO move hardcoded strings to variables
    sudo sed -i -E "s:(\s*[$]local_package_dir.*=).*$:\1 \"/home/vagrant/packs\":g" /etc/puppet/manifests/nodes.pp
    sudo sed -i -E "s:(\s*[$]mb_ip.*=).*$:\1 \"$IP_ADDR\":g" /etc/puppet/manifests/nodes.pp
    sudo sed -i -E "s:(\s*[$]mb_port.*=).*$:\1 \"$MB_PORT\":g" /etc/puppet/manifests/nodes.pp
    sudo sed -i -E "s:(\s*[$]cep_ip.*=).*$:\1 \"$IP_ADDR\":g" /etc/puppet/manifests/nodes.pp
    sudo sed -i -E "s:(\s*[$]cep_port.*=).*$:\1 \"$CEP_PORT\":g" /etc/puppet/manifests/nodes.pp
    # TODO move hardcoded strings to variables
    sudo sed -i -E "s:(\s*[$]truststore_password.*=).*$:\1 \"wso2carbon\":g" /etc/puppet/manifests/nodes.pp

    sudo wget -q -c -P /etc/puppet/modules/java/files \
              --no-cookies --no-check-certificate \
              --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" \
              "http://download.oracle.com/otn-pub/java/jdk/7u51-b13/jdk-7u51-linux-x64.tar.gz"

    sudo sed -i -E 's:(\s*[$]java_name.*=).*$:\1 "jdk1.7.0_51":g' /etc/puppet/manifests/nodes.pp
    sudo sed -i -E 's:(\s*[$]java_distribution.*=).*$:\1 "jdk-7u51-linux-x64.tar.gz":g' /etc/puppet/manifests/nodes.pp
  fi
  popd 
}

function cartridge_setup() {

  echo "TODO: cartridge setup"

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
   mvn clean install -DskipTests
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
   maven_clean_install
   puppet_setup # has a dependency on maven_clean_install
   cartridge_setup
   installer
}

main "$@"
