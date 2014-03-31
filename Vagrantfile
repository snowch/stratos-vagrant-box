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

Vagrant.configure("2") do |config|

    # use the opscode vagrant box definitions because they have a 40Gb disk which should be enough for
    # stratos. ubuntu cloud images only have 10Gb which is not enough.

    # 64 bit machine
    config.vm.box = "opscode-ubuntu-12.04-64"
    config.vm.box_url = "http://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_ubuntu-12.04_chef-provisionerless.box"

    # 32 bit machine
    #config.vm.box = "opscode-ubuntu-12.04-32"
    #config.vm.box_url = "http://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_ubuntu-12.04-i386_chef-provisionerless.box"   

    stratos.vm.hostname = "paas.stratos.com"
    
    # put stratos on the same private network as cloudstack so they can talk to each other
    config.vm.network :private_network, :ip => STRATOS_IP

    # make the stratos setup script available in the /home/vagrant folder
    config.vm.provision "shell", inline: "ln -sf /vagrant/stratos_dev.sh /home/vagrant/stratos_dev.sh", privileged: false
    config.vm.provision "shell", inline: "ln -sf /vagrant/iaas.conf /home/vagrant/iaas.conf", privileged: false

    config.vm.provider "virtualbox" do |v|
      v.customize ["modifyvm", :id, "--memory", 2048]
    end

end
