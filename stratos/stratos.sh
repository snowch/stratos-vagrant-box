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

# Assume ActiveMQ for Messaging, and installed locally.
MB_IP_ADDR="127.0.0.1"
MB_PORT=61616

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

########################################################
# You should not need to change anything below this line
########################################################

if ! egrep -q "Ubuntu (12.04|13.04|13.10)" /etc/issue; then
  echo "WARNING: This script has only been tested on Ubuntu 12.04, 13.04 and 13.10"
  read -p "Press [Enter] key to continue (CTRL-C to quit)..."  
  clear
fi

if [[ ! $(whoami) =~ (vagrant|stratos) ]] ; then
  echo "This script is designed to be run as user 'vagrant' or 'stratos'."
  echo ""
  echo "You can create a user account, as administrator:"
  echo ""
  echo "  useradd --create-home -s /bin/bash vagrant"
  echo "  echo 'vagrant:vagrant' | chpasswd"
  echo "  echo 'vagrant ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/vagrant"
  echo "  echo 'Defaults:vagrant secure_path=/sbin:/usr/sbin:/usr/bin:/bin:/usr/local/sbin:/usr/local/bin' >> /etc/sudoers.d/vagrant"
  echo ""
  read -p "If you would like to continue anyway, press [Enter] key to continue (CTRL-C to quit)..."  
  clear
fi

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
      m) puppet_base_setup; exit $? ;;
      p) puppet_stratos_setup; exit $? ;;
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
Usage: $progname -[f|w|c|b|m|p|n|d|h]

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
       $progname -m && $progname -w && $progname -c && $progname -b && $progname -p && $progname -n

    -w Download pre-requisite files such as MYSQLJ


    -c Checkout Stratos 'master' code.  
       Each time you run this command, this script will do a 'git pull'

    -b Builds Stratos.  Equivalent to running: 'mvn clean install'
       You will probably want to re-run this after you modify or pull new source 

    -m Setup base puppet master

    -p Setup puppet master for Stratos. 
       You will probably want to re-run this after you re-build Stratos.

    -n Install Stratos and CLI (and startup Stratos).
       You will probably want to re-run this after you re-setup Puppet.
       Use 'tail -f ${HOME}/stratos-log/stratos-setup.log' to watch output.

       When you see the 'Servers Started' message, you should be able to connect
       with your browser to:

       Hostname: https://$IP_ADDR:9443
       Username: admin
       Password: admin

    -d Setup a development environment with lubuntu desktop and eclipse.
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
  sudo apt-get upgrade -y
  sudo apt-get install -y --no-install-recommends git maven openjdk-7-jdk 

  if [ "$(arch)" != "x86_64" ]
  then
    fix_git_tls_bug
  fi

  sudo sh -c "
     export DEBIAN_FRONTEND=noninteractive
     echo mysql-server-5.1 mysql-server/root_password password password | debconf-set-selections
     echo mysql-server-5.1 mysql-server/root_password_again password password | debconf-set-selections
     apt-get -y install mysql-server
     "

  if [ "$(arch)" == "x86_64" ]
  then
    grep '^export MAVEN_OPTS' .profile || echo 'export MAVEN_OPTS="-Xmx2048m -XX:MaxPermSize=512m -XX:ReservedCodeCacheSize=256m -Xdebug -Xrunjdwp:transport=dt_socket,address=8888,server=y,suspend=n"' >> .profile
  else
    grep '^export MAVEN_OPTS' .profile || echo 'export MAVEN_OPTS="-Xmx1024m -XX:MaxPermSize=512m -XX:ReservedCodeCacheSize=256m -Xdebug -Xrunjdwp:transport=dt_socket,address=8888,server=y,suspend=n"' >> .profile
  fi
  . .profile
}

function puppet_base_setup() {

  echo -e "\e[32mSetting up puppet master base\e[39m"

  pushd $PWD
  cd ${HOME}

  sudo apt-get update
  sudo apt-get install -y git
  # bc is required - see https://github.com/thilinapiy/puppetinstall/issues/6 
  sudo apt-get install -y bc

  # FIXME make this idempotent - i.e. same result each time it is run
  if [ ! -d puppetinstall ]
  then
    git clone https://github.com/thilinapiy/puppetinstall
    cd puppetinstall
    echo '' | sudo ./puppetinstall -m -d $DOMAINNAME -s $PUPPET_IP_ADDR
  fi

  [ -d /etc/puppet/modules/agent/files ] || sudo mkdir -p /etc/puppet/modules/agent/files
  [ -d /etc/puppet/modules/java/files ] || sudo mkdir -p /etc/puppet/modules/java/files
  [ -d /etc/puppet/modules/tomcat/files ] || sudo mkdir -p /etc/puppet/modules/tomcat/files

  #if [ "$(arch)" == "x86_64" ]
  #then
  #  JAVA_ARCH="x64"
  #else
  #  JAVA_ARCH="i586"
  #fi

  # WARNING: currently Stratos only supports 64 bit cartridges
  JAVA_ARCH="x64"

  JDK="jdk-7u51-linux-${JAVA_ARCH}.tar.gz" 
  JDK_SHA1="bee3b085a90439c833ce18e138c9f1a615152891"


  download_jdk="true"
  if [[ -e $STRATOS_PACK_PATH/$JDK ]]; then
    echo "Found JDK in $STRATOS_PACK_PATH folder, so not downloading again."
    sha1=$(sha1sum $STRATOS_PACK_PATH/$JDK | cut -d' ' -f1)

    if [[ "$sha1" == "$JDK_SHA1" ]]; then
       download_jdk="false"
    else
       rm $STRATOS_PACK_PATH/$JDK
    fi
  fi
 
  if [[ $download_jdk == "true" ]]; then
 
       # Oracle download is so unreliable we need to be a bit more informative with the error feedback
       trap - ERR

       echo 'Downloading Oracle JDK'
       wget -N -nv -c -P $STRATOS_PACK_PATH \
            --no-cookies --no-check-certificate \
            --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" \
            "http://download.oracle.com/otn-pub/java/jdk/7u51-b13/${JDK}"

       if [ $? -ne 0 ]
       then
         echo "Failed to download Oracle JDK."
         echo "Please retry later, or manually download to the $STRATOS_PACK_PATH folder"
         exit 1
       fi
       trap 'error ${LINENO}' ERR
  fi

  # make the JDK available to puppet
  sudo cp -f ${STRATOS_PACK_PATH}/${JDK} /etc/puppet/modules/java/files/

  # download tomcat
  wget -N -nv -c -P $STRATOS_PACK_PATH $TOMCAT_URL

  # make tomcat available to puppet
  sudo cp -f ${STRATOS_PACK_PATH}/$(basename $TOMCAT_URL) /etc/puppet/modules/tomcat/files/

  # add unqualified hostname to /etc/hosts because that isn't done by puppetinstall
  sudo sed -i -e "s@puppet.${DOMAINNAME}\s*\$@puppet.${DOMAINNAME} puppet@g" /etc/hosts

  sudo sh -c "echo \"*.$DOMAINNAME\" > /etc/puppet/autosign.conf"

  echo -e "\e[32mFinished setting up puppet master base\e[39m"

  popd

}

function puppet_stratos_setup() {

  echo -e "\e[32mSetting up puppet master for Stratos\e[39m"

  pushd $PWD

  # Stratos specific puppet setup

  sudo cp -rf $STRATOS_SOURCE_PATH/tools/puppet3/manifests/* /etc/puppet/manifests/
  sudo cp -rf $STRATOS_SOURCE_PATH/tools/puppet3/modules/* /etc/puppet/modules/
  sudo cp -f $STRATOS_SOURCE_PATH/products/cartridge-agent/modules/distribution/target/apache-stratos-cartridge-agent-*.zip /etc/puppet/modules/agent/files
  sudo cp -f $STRATOS_SOURCE_PATH/products/load-balancer/modules/distribution/target/apache-stratos-load-balancer-*.zip /etc/puppet/modules/agent/files

  # WARNING: currently Stratos only supports 64 bit cartridges
  JAVA_ARCH="x64"

  sudo sed -i -E "s:(\s*[$]java_name.*=).*$:\1 \"jdk1.7.0_51\":g" /etc/puppet/manifests/nodes.pp
  sudo sed -i -E "s:(\s*[$]java_distribution.*=).*$:\1 \"jdk-7u51-linux-${JAVA_ARCH}.tar.gz\":g" /etc/puppet/manifests/nodes.pp

  sudo sed -i -E "s:(\s*[$]local_package_dir.*=).*$:\1 \"$STRATOS_PACK_PATH\":g" /etc/puppet/manifests/nodes.pp
  sudo sed -i -E "s:(\s*[$]mb_ip.*=).*$:\1 \"$IP_ADDR\":g" /etc/puppet/manifests/nodes.pp
  sudo sed -i -E "s:(\s*[$]mb_port.*=).*$:\1 \"$MB_PORT\":g" /etc/puppet/manifests/nodes.pp
  # TODO move hardcoded strings to variables
  sudo sed -i -E "s:(\s*[$]truststore_password.*=).*$:\1 \"wso2carbon\":g" /etc/puppet/manifests/nodes.pp

  popd 

  echo -e "\e[32mFinished setting up puppet\e[39m"
}

function installer() {

  echo -e "\e[32mRunning Stratos Installer\e[39m"

  pushd $PWD

  kill_servers

  [ -d $STRATOS_SETUP_PATH ] || mkdir $STRATOS_SETUP_PATH
  [ -d /etc/puppet/modules/agent/files/ ] || sudo mkdir -p /etc/puppet/modules/agent/files/
  [ -d /etc/puppet/modules/agent/files/activemq ] || sudo mkdir -p /etc/puppet/modules/agent/files/activemq

  if [ -d $STRATOS_PATH ]
  then
    echo "Found existing Stratos instllation folder: $STRATOS_PATH"
    echo "Delete this folder and the Stratos 'userstore' database [y/n]? "
    read answer
    if [[ $answer == y ]] ; then
        sudo rm -rf $STRATOS_PATH
        mysql -u root -p'password' -e 'drop database if exists userstore;' mysql
    else
        echo "Can't install on top of existing $STRATOS_PATH folder.  Exiting."
        exit 1
    fi
  fi

  # TODO use sed line replacement
  grep -q '^export STRATOS_CLI_HOME' ~/.profile || echo "export STRATOS_CLI_HOME=$STRATOS_CLI_HOME" >> ~/.profile
  . ~/.profile
  export STRATOS_CLI_HOME

  # extract cli zip file
  cli_file=$(find $STRATOS_SOURCE_PATH/products/stratos-cli/distribution/target/apache-stratos-cli-*.zip)
  rm -rf $STRATOS_PATH/$(basename $cli_file)
  unzip $cli_file -d $STRATOS_PATH
  STRATOS_CLI_HOME=$STRATOS_PATH/$(basename $cli_file)
 
  cp -rpf $STRATOS_SOURCE_PATH/tools/stratos-installer/* $STRATOS_SETUP_PATH/
  cp -f $STRATOS_SOURCE_PATH/products/stratos/modules/distribution/target/apache-stratos-*.zip $STRATOS_PACK_PATH/

  sudo cp -f $STRATOS_SOURCE_PATH/products/cartridge-agent/modules/distribution/target/apache-stratos-cartridge-agent-*.zip /etc/puppet/modules/agent/files/
  sudo cp -f $STRATOS_SOURCE_PATH/products/load-balancer/modules/distribution/target/apache-stratos-load-balancer-*.zip /etc/puppet/modules/lb/files/

  if [ ! -e $STRATOS_PACK_PATH/$(basename $ACTIVEMQ_URL) ]
  then
     echo "Downloading $ACTIVEMQ_URL/$ACTIVEMQ_FILE"
     wget -N -nv -P $STRATOS_PACK_PATH $ACTIVEMQ_URL
  fi

  if [ -e tmp-activemq ] 
  then
    # clean up from any previous installation attempts
    rm -rf tmp-activemq
  fi
  mkdir tmp-activemq
  tar -C tmp-activemq -xzf $STRATOS_PACK_PATH/$(basename $ACTIVEMQ_URL) 
  cp -f tmp-activemq/apache-activemq-5.9.1/lib/activemq-broker-5.9.1.jar $STRATOS_PACK_PATH/
  cp -f tmp-activemq/apache-activemq-5.9.1/lib/activemq-client-5.9.1.jar $STRATOS_PACK_PATH/
  cp -f tmp-activemq/apache-activemq-5.9.1/lib/geronimo-j2ee-management_1.1_spec-1.0.1.jar $STRATOS_PACK_PATH/
  cp -f tmp-activemq/apache-activemq-5.9.1/lib/geronimo-jms_1.1_spec-1.1.1.jar $STRATOS_PACK_PATH/
  rm -rf tmp-activemq

  if [ ! -e $STRATOS_PACK_PATH/$(basename $HAWTBUF_URL) ]
  then
     echo "Downloading $HAWTBUF_URL"
     wget -N -nv -P $STRATOS_PACK_PATH $HAWTBUF_URL
  fi

  # TODO refactor this duplicated code
  sudo cp -f $STRATOS_PACK_PATH/activemq-broker-5.9.1.jar /etc/puppet/modules/agent/files/activemq/
  sudo cp -f $STRATOS_PACK_PATH/activemq-client-5.9.1.jar /etc/puppet/modules/agent/files/activemq/
  sudo cp -f $STRATOS_PACK_PATH/geronimo-j2ee-management_1.1_spec-1.0.1.jar /etc/puppet/modules/agent/files/activemq/
  sudo cp -f $STRATOS_PACK_PATH/geronimo-jms_1.1_spec-1.1.1.jar /etc/puppet/modules/agent/files/activemq/
  sudo cp -f $STRATOS_PACK_PATH/$(basename $HAWTBUF_URL) /etc/puppet/modules/agent/files/activemq/

  sudo cp -f $STRATOS_PACK_PATH/activemq-broker-5.9.1.jar /etc/puppet/modules/lb/files/
  sudo cp -f $STRATOS_PACK_PATH/activemq-client-5.9.1.jar /etc/puppet/modules/lb/files/
  sudo cp -f $STRATOS_PACK_PATH/geronimo-j2ee-management_1.1_spec-1.0.1.jar /etc/puppet/modules/lb/files/
  sudo cp -f $STRATOS_PACK_PATH/geronimo-jms_1.1_spec-1.1.1.jar /etc/puppet/modules/lb/files/
  sudo cp -f $STRATOS_PACK_PATH/$(basename $HAWTBUF_URL) /etc/puppet/modules/lb/files/

  CFG_FILE=$STRATOS_SETUP_PATH/conf/setup.conf

  sed -i "s:^export setup_path=.*:export setup_path=$STRATOS_SETUP_PATH:g" $CFG_FILE
  sed -i "s:^export stratos_packs=.*:export stratos_packs=$STRATOS_PACK_PATH:g" $CFG_FILE
  sed -i "s:^export stratos_path=.*:export stratos_path=$STRATOS_PATH:g" $CFG_FILE
  sed -i "s:^export mysql_connector_jar=.*:export mysql_connector_jar=$STRATOS_PACK_PATH/$(basename $MYSQLJ_URL):g" $CFG_FILE
  sed -i "s:^export JAVA_HOME=.*:export JAVA_HOME=$JAVA_HOME:g" $CFG_FILE
  sed -i "s:^export log_path=.*:export log_path=$HOME/stratos-log:g" $CFG_FILE
  sed -i "s:^export host_user=.*:export host_user=$(whoami):g" $CFG_FILE
  sed -i "s:^export stratos_domain=.*:export stratos_domain=$DOMAINNAME:g" $CFG_FILE
  sed -i "s:^export offset=.*:export offset=0:g" $CFG_FILE
  sed -i "s:^export mb_ip=.*:export mb_ip=$MB_IP_ADDR:g" $CFG_FILE
  sed -i "s:^export mb_port=.*:export mb_port=$MB_PORT:g" $CFG_FILE
  sed -i "s:^export puppet_ip=.*:export puppet_ip=$PUPPET_IP_ADDR:g" $CFG_FILE
  sed -i "s:^export puppet_hostname=.*:export puppet_hostname=$PUPPET_HOSTNAME:g" $CFG_FILE
  # set puppet_environment to a dummy value
  sed -i "s:^export puppet_environment=.*:export puppet_environment=XXXXXXXXXXXXXXXXX:g" $CFG_FILE
  sed -i "s:^export cep_artifacts_path=.*:export cep_artifacts_path=$STRATOS_SOURCE_PATH/extensions/cep/artifacts/:g" $CFG_FILE

  sed -i "s:^export userstore_db_hostname=.*:export userstore_db_hostname=\"localhost\":g" $CFG_FILE
  sed -i "s:^export userstore_db_schema=.*:export userstore_db_schema=\"userstore\":g" $CFG_FILE
  sed -i "s:^export userstore_db_port=.*:export userstore_db_port=\"3306\":g" $CFG_FILE
  sed -i "s:^export userstore_db_user=.*:export userstore_db_user=\"root\":g" $CFG_FILE
  sed -i "s:^export userstore_db_pass=.*:export userstore_db_pass=\"password\":g" $CFG_FILE

  # read variables from iaas.conf, escaping colons to prevent later sed statements throwing an error
  source <(sed 's/:/\\\\:/g' ${HOME}/iaas.conf)

  # Now apply the changes to stratos-setup.conf for each of the IaaS

  # EC2
  sed -i "s:^export ec2_provider_enabled=.*:export ec2_provider_enabled='$ec2_provider_enabled':g" $CFG_FILE
  sed -i "s:^export ec2_identity=.*:export ec2_identity='$ec2_identity':g" $CFG_FILE
  sed -i "s:^export ec2_credential=.*:export ec2_credential='$ec2_credential':g" $CFG_FILE
  sed -i "s:^export ec2_keypair_name=.*:export ec2_keypair_name='$ec2_keypair_name':g" $CFG_FILE
  sed -i "s:^export ec2_owner_id=.*:export ec2_owner_id='$ec2_owner_id':g" $CFG_FILE
  sed -i "s:^export ec2_availability_zone=.*:export ec2_availability_zone='$ec2_availability_zone':g" $CFG_FILE
  sed -i "s:^export ec2_security_groups=.*:export ec2_security_groups='$ec2_security_groups':g" $CFG_FILE

  # Openstack
  sed -i "s:^export openstack_provider_enabled=.*:export openstack_provider_enabled='$openstack_provider_enabled':g" $CFG_FILE
  sed -i "s:^export openstack_identity=.*:export openstack_identity='$openstack_identity':g" $CFG_FILE
  sed -i "s:^export openstack_credential=.*:export openstack_credential='$openstack_credential':g" $CFG_FILE
  sed -i "s:^export openstack_jclouds_endpoint=.*:export openstack_jclouds_endpoint='$openstack_jclouds_endpoint':g" $CFG_FILE
  sed -i "s:^export openstack_keypair_name=.*:export openstack_keypair_name='$openstack_keypair_name':g" $CFG_FILE
  sed -i "s:^export openstack_security_groups=.*:export openstack_security_groups='$openstack_security_groups':g" $CFG_FILE

  # vCloud
  sed -i "s:^export vcloud_provider_enabled=.*:export vcloud_provider_enabled='$vcloud_provider_enabled':g" $CFG_FILE
  sed -i "s:^export vcloud_identity=.*:export vcloud_identity='$vcloud_identity':g" $CFG_FILE
  sed -i "s:^export vcloud_credential=.*:export vcloud_credential='$vcloud_credential':g" $CFG_FILE
  sed -i "s:^export vcloud_jclouds_endpoint=.*:export vcloud_jclouds_endpoint='$vcloud_jclouds_endpoint':g" $CFG_FILE
    

  cd $STRATOS_SETUP_PATH
  chmod +x *.sh

  [ -d $STRATOS_PATH ] || mkdir $STRATOS_PATH
  echo '' | sudo ./setup.sh -p "default" -s

  # fix bug where stratos can't be started over ssh connection
  sed -i 's:\(nohup.*\)args >:\1args < /dev/null >:g' $STRATOS_PATH/apache-stratos-default/bin/stratos.sh

  # fix bug where activemq can't be started over ssh connection
  patch $STRATOS_PATH/apache-activemq-5.9.1/bin/activemq < /vagrant/stratos/activemq.patch

  # turn off error handling for grep
  trap - ERR
  grep -q 'su -c "/home/vagrant/stratos.sh -s" -s /bin/sh vagrant' /etc/rc.local
  if [ $? == 1 ]
  then
    read -d '' REPLACE << EOF
su -c "/home/vagrant/stratos.sh -s" -s /bin/sh vagrant
exit 0
EOF
    sudo perl -i.bak -pe 's~^exit 0~'"${REPLACE}"'~g' /etc/rc.local
  fi

  popd
}

function start_servers() {

  $STRATOS_PATH/apache-activemq-5.9.1/bin/activemq restart > /dev/null 2>&1

  $STRATOS_PATH/apache-stratos-default/bin/stratos.sh -Dprofile=default --restart > /dev/null 2>&1

  echo "Servers starting."
  echo "Check status using: $progname -t"
  echo "Logs:"
  echo "  ActiveMQ -> ./stratos/apache-activemq-5.9.1/data/activemq.log"
  echo "  Stratos  -> ./stratos/apache-stratos-default/repository/logs/wso2carbon.log"
}

function kill_servers() {

  # stop trapping errors.  if stopping stratos fails, still try to stop activemq
  trap - ERR

  echo "Please wait - servers are shutting down." 
  
  $STRATOS_PATH/apache-stratos-default/bin/stratos.sh --stop > /dev/null 2>&1

  $STRATOS_PATH/apache-activemq-5.9.1/bin/activemq stop > /dev/null 2>&1

  stratos_pid=$(cat $STRATOS_PATH/apache-stratos-default/wso2carbon.pid)
  
  count=0
  while ( $progname -t | grep -q 'Stratos is running' );  do 
    echo 'Waiting for Stratos to stop running.'
    let "count=count+1"
    if [[ $count -eq 5 ]]; then
      kill -SIGKILL $stratos_pid
      break
    fi 
    sleep 10s
    kill -SIGINT $stratos_pid
  done

  echo > $STRATOS_PATH/apache-stratos-default/wso2carbon.pid

  # turn error handling back on
  trap 'error ${LINENO}' ERR

  echo "Servers stopped."
  echo "  Check status using $progname -t"
  echo "  Start again using $progname -s"
}

function servers_status() {

  # ignore errors
  trap - ERR

  $STRATOS_PATH/apache-activemq-5.9.1/bin/activemq status | tail -1

  # find the stratos pid
  stratos_pid=$(cat $STRATOS_PATH/apache-stratos-default/wso2carbon.pid)

  # check all java running process pids
  java_pids=$(pgrep -u $(whoami) -f java)

  # if there is process running for statos 
  echo $java_pids | grep -q "$stratos_pid"
  if [ $? -eq 0 ]
  then
    echo "Stratos is running (pid '$stratos_pid')"
  else
    echo "Stratos is not running"
  fi

  echo "Logs:"
  echo "  ActiveMQ -> ./stratos/apache-activemq-5.9.1/data/activemq.log"
  echo "  Stratos  -> ./stratos/apache-stratos-default/repository/logs/wso2carbon.log"
}

function development_environment() {

   pushd $PWD

   echo -e "\e[32mSetting up development environment.\e[39m"

   if [ ! -d ${STRATOS_PATH} ]
   then
     echo "It appears that Stratos has not been installed yet, so quitting."
     exit 1
   fi

   # make sure stratos isn't running because it will block the jvm debugger
   kill_servers

   sudo apt-get update
   sudo apt-get upgrade -y
   sudo apt-get install -y --no-install-recommends lubuntu-desktop eclipse-jdt xvfb lxde firefox
   sudo apt-get install -y --no-install-recommends vnc4server xrdp

   # switch off screensaver - it can kill the CPU
   echo lxsession > ~/.xsession
   echo 'mode: off' > ~/.xscreensaver

   # switch off update manager popup
   # FIXME: this doesn't seem to work
   sudo sed -i 's/NoDisplay=true/NoDisplay=false/g' /etc/xdg/autostart/*.desktop

   cd $STRATOS_SOURCE_PATH
   echo "Running 'mvn eclipse:eclipse'"
   mvn -q eclipse:eclipse

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

   mvn -Declipse.workspace=${HOME}/workspace/ eclipse:configure-workspace

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
   
   mvn clean install -DskipTests
   popd
}

function force_clean () {
   
   pushd $PWD
   echo -e "\e[32mIMPORTANT\e[39m"
   echo "Reset your environment?  This will lose any changes you have made."
   echo
   read -p "Please close eclipse, stop any maven jobs and press [Enter] key to continue."
   
   cd $STRATOS_SOURCE_PATH
   mvn clean
   
   rm -rf ${HOME}/workspace-stratos
   
   rm -rf ${HOME}/.m2
   
   popd
}

function initial_setup() {
   
   echo -e "\e[32mPerforming initial setup.\e[39m"
   puppet_base_setup
   downloads   
   prerequisites
   checkout
   maven_clean_install
   puppet_stratos_setup # has a dependency on maven_clean_install
   installer
}

main "$@"
