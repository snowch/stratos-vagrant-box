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

require 'net/scp'

CLOUDSTACK_IP="192.168.56.10"
STRATOS_IP="192.168.56.5"


Vagrant.configure("2") do |config|

  # 
  # Define a box for setting up Stratos
  #
  config.vm.define "stratos" do |stratos|

    # use the opscode vagrant box definitions because they have a 40Gb disk which should be enough for
    # stratos. ubuntu cloud images only have 10Gb which is not enough.

    # 64 bit machine
    stratos.vm.box = "opscode-ubuntu-12.04-64"
    stratos.vm.box_url = "http://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_ubuntu-12.04_chef-provisionerless.box"

    # 32 bit machine
    #stratos.vm.box = "opscode-ubuntu-12.04-32"
    #stratos.vm.box_url = "http://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_ubuntu-12.04-i386_chef-provisionerless.box"   

    stratos.vm.hostname = "paas.stratos.com"
    
    # put stratos on the same private network as cloudstack so they can talk to each other
    stratos.vm.network :private_network, :ip => STRATOS_IP

    # make the stratos setup script available in the /home/vagrant folder
    stratos.vm.provision "shell", inline: "ln -sf /vagrant/stratos_dev.sh /home/vagrant/stratos_dev.sh", privileged: false
    stratos.vm.provision "shell", inline: "ln -sf /vagrant/iaas.conf /home/vagrant/iaas.conf", privileged: false

    stratos.vm.provider "virtualbox" do |v|
      v.customize ["modifyvm", :id, "--memory", 2048]
    end
  end


  # 
  # Define a box for running cloudstack
  #
  config.vm.define "cloudstack" do |cloudstack|

    # disable mounting vagrant folder, no guest additions installed
    cloudstack.vm.synced_folder ".", "/vagrant", disabled: true

    # disable checking for vbguest version because vbguest is
    # not supported in a xen dom0 
    if Vagrant.has_plugin?("vagrant-vbguest")
      cloudstack.vbguest.auto_update = false
    end

    # use a pre-existing box that is pre-configured for cloudstack
    cloudstack.vm.box = "DevCloud"
    cloudstack.vm.box_url = "https://github.com/imduffy15/devcloud/releases/download/v0.2/devcloud.box"

    cloudstack.vm.hostname = "devcloud.cloudstack.org"

    # devcloud needs a private network that is not managed by vagrant
    cloudstack.vm.network :private_network, :auto_config => false , :ip => CLOUDSTACK_IP

    # allow enough memory for cloudstack and set the nic to promiscous
    cloudstack.vm.provider "virtualbox" do |v|
      v.customize ["modifyvm", :id, "--memory", 4096]
      v.customize [ "modifyvm", :id, "--nicpromisc2", "allow-all" ]
      #v.gui = true
    end

    # virtualbox tools don't work on the xen kernel, so vagrant shared folders do not work
    # this is a hack to get the cloudstack setup script onto guest without shared folders
    if ARGV[0] == "provision"
      begin
        Net::SCP.start(CLOUDSTACK_IP, "vagrant", :password => "vagrant") do |scp|
          scp.upload! "iaas_scripts/cloudstack/cloudstack_dev.sh", "cloudstack_dev.sh"
        end
        cloudstack.vm.provision "shell", inline: "chmod +x /home/vagrant/cloudstack_dev.sh"
        if ENV['ACTION'] == 'setup-cloudstack'
          cloudstack.vm.provision "shell", inline: ". /home/vagrant/cloudstack_dev.sh -i", privileged: false
        elsif ENV['ACTION'] == 'run-cloudstack'
          cloudstack.vm.provision "shell", inline: ". /home/vagrant/cloudstack_dev.sh -r", privileged: false
        else
          msg = "ERROR: Unknown or missing ACTION '#{ENV['ACTION']}'.\n\n"\
                "Try using an ACTION of 'setup-cloudstack' or 'run-cloudstack', E.g.\n"\
                "ACTION='run-cloudstack' vagrant provision cloudstack\n"
          abort msg
        end
      rescue
        # box may not be running - ignore this error
      end
    end

  end


end
