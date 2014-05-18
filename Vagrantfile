# -*- mode: ruby -*-
# vi: set ft=ruby :

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


STRATOS_IP="192.168.56.5"
OPENSTACK_IP="192.168.92.30"

Vagrant.configure("2") do |config|

    # use the opscode vagrant box definitions because they have a 40Gb disk which should be enough for
    # stratos. ubuntu cloud images only have 10Gb which is not enough.

    # 64 bit machine
    config.vm.box = "opscode-ubuntu-13.04-64"
    config.vm.box_url = "http://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_ubuntu-13.04_chef-provisionerless.box"

    # puppetinstall scripts hardcode the guest name to 'puppet.$DOMAIN' so lets keep with that
    config.vm.hostname = "puppet.stratos.com"

    # Use vagrant cachier if it is available - it will speed up repeated 
    # 'vagrant destroy' and 'vagrant up' calls
    if Vagrant.has_plugin?("vagrant-cachier")
       config.cache.scope = :box
    end

# Using a synced folder can break the build due to the maven file name lengths
#    config.vm.synced_folder File.expand_path("./m2_repo"),
#	"/home/vagrant/.m2/", 
#        :create => true,
#	:mount_option => "dmode=777,fmode=666"
    
    # put stratos on the same private network as cloudstack so they can talk to each other
    config.vm.network :private_network, :ip => STRATOS_IP

    config.vm.network :private_network, :ip => OPENSTACK_IP, :netmask => "255.255.255.0"

    # apply provisioning script
    config.vm.provision "shell", inline: $stratos_script, privileged: false
    config.vm.provision "shell", inline: $openstack_script, privileged: false

    # virtualbox customisations
    config.vm.provider "virtualbox" do |v|
      v.customize ["modifyvm", :id, "--memory", 4096 ]

      # uncomment these to use the virtualbox gui:
      # v.gui = true
      # v.customize ["modifyvm", :id, "--clipboard", "bidirectional"]
    end

    # If you want to customise the Vagrantfile just for your environment, try
    # putting your customisations in Vagrantfile.stratos.extensions
    # 
    # For example, I use it to join my LAN network when running vagrant on a server
    #   stratos.vm.network "public_network"
    begin
      eval(File.open("Vagrantfile.extensions").read)
      puts "Loaded Vagrantfile.extensions"
    rescue
      # do nothing
    end

end


$stratos_script = <<SCRIPT
# copy example stratos version conf file if it doesn't already exist
if [ ! -e /vagrant/stratos_version.conf ]; then
  cp /vagrant/stratos_version.conf.example /vagrant/stratos_version.conf
  sed -i '1,2d' /vagrant/stratos_version.conf
fi
ln -sf /vagrant/stratos_version.conf /home/vagrant/stratos_version.conf

# remove the example text from the first two lines

# copy stratos script
ln -sf /vagrant/stratos/stratos.sh /home/vagrant/stratos.sh

# copy iaas conf file if it doesn't already exist
[ -e iaas.conf ] || cp /vagrant/iaas.conf.example /home/vagrant/iaas.conf

# remove the example text from the first two lines
sed -i '1,2d' iaas.conf

# allow downloaded files to go the vagrant folder so downloading again is not 
# required after performing a 'vagrant destroy' 
[ -d /vagrant/downloads/stratos-packs ] || mkdir -p /vagrant/downloads/stratos-packs

ln -sf /vagrant/downloads/stratos-packs /home/vagrant/stratos-packs
SCRIPT


$openstack_script = <<SCRIPT
# copy openstack scripts and demo keypair
ln -sf /vagrant/openstack-docker/openstack-docker.sh /home/vagrant/openstack-docker.sh

if [ ! -e /home/vagrant/openstack-demo-keypair.pem ]; then
  cp -f /vagrant/openstack-docker/openstack-demo-keypair.pem /home/vagrant/openstack-demo-keypair.pem
  chmod 600 /home/vagrant/openstack-demo-keypair.pem
fi

[ -d /vagrant/downloads/openstack-docker ] || mkdir -p /vagrant/downloads/openstack-docker

SCRIPT

