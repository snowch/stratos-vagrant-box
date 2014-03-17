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

  config.vm.define "cloudstack" do |cloudstack|

    # disable mounting vagrant folder, no guest additions installed
    cloudstack.vm.synced_folder ".", "/vagrant", disabled: true

    # disable checking for vbguest version because vbguest is
    # not supported in a xen dom0 
    if Vagrant.has_plugin?("vagrant-vbguest")
      cloudstack.vbguest.auto_update = false
    end

    cloudstack.vm.box = "DevCloud"
    cloudstack.vm.box_url = "https://github.com/imduffy15/devcloud/releases/download/v0.2/devcloud.box"

    cloudstack.vm.hostname = "devcloud.cloudstack.org"
    cloudstack.vm.network :private_network, :auto_config => false , :ip => CLOUDSTACK_IP

    cloudstack.vm.provider "virtualbox" do |v|
      v.customize ["modifyvm", :id, "--memory", 4096]
      v.customize [ "modifyvm", :id, "--nicpromisc2", "allow-all" ]
      #v.gui = true
    end

    # hack to get script onto guest without shared folders
    if ARGV[0] == "provision"
      Net::SCP.start(CLOUDSTACK_IP, "vagrant", :password => "vagrant") do |scp|
        scp.upload! "cloudstack_dev.sh", "cloudstack_dev.sh"
      end
      cloudstack.vm.provision "shell", inline: "chmod +x /home/vagrant/cloudstack_dev.sh"
      cloudstack.vm.provision "shell", inline: ". /home/vagrant/cloudstack_dev.sh -i", privileged: false
    end

  end


  config.vm.define "stratos" do |stratos|

    stratos.vm.box = "opscode-ubuntu-12.04"
    stratos.vm.box_url = "http://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_ubuntu-12.04_chef-provisionerless.box"
    stratos.vm.hostname = "paas.stratos.org"
    stratos.vm.network :private_network, :auto_config => false , :ip => STRATOS_IP

    stratos.vm.provision "shell", inline: "ln -sf /vagrant/stratos_dev.sh /home/vagrant/stratos_dev.sh", privileged: false
  end

end
