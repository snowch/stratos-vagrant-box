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


$script = <<SCRIPT
wget --no-check-certificate https://raw.github.com/snowch/devcloud-script/master/cloudstack_dev.sh
chmod +x cloudstack_dev.sh
SCRIPT


Vagrant.configure("2") do |config|

  # disable mounting vagrant folder, no guest additions installed
  config.vm.synced_folder ".", "/vagrant", disabled: true

  config.vm.box = "DevCloud"

  config.vm.box_url = "https://github.com/imduffy15/devcloud/releases/download/v0.2/devcloud.box"

  config.vm.hostname = "devcloud.cloudstack.org"
  config.vm.network :private_network, :auto_config => false , :ip => "192.168.56.10"

  config.vm.provider "virtualbox" do |v|
    v.customize ["modifyvm", :id, "--memory", 4096]
    v.customize [ "modifyvm", :id, "--nicpromisc2", "allow-all" ]
    #v.gui = true
  end
  
  config.vm.provision "shell", inline: $script, privileged: false
  
end
