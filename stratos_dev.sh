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

function usage () {
   cat <<EOF
Usage: $progname -[i|c|r|p|d|f]
where:
    -i checkout and build
EOF
   exit 0
}


function checkout() {

  echo -e "\e[32mChecking out.\e[39m"

  pushd $PWD
  cd /home/vagrant

  if [ ! -d /home/vagrant/incubator-stratos ]
  then
     git clone https://git-wip-us.apache.org/repos/asf/incubator-stratos.git
  else
     cd /home/vagrant/incubator-stratos
     git checkout master
     git pull
  fi

  cd /home/vagrant/cloudstack
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
   
   checkout
   maven_clean_install
}

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
