## Stratos Runtime and Development Environments 

### Stratos Runtime Environment

#### Overview

This project contains scripts to automate the setup of Ubuntu 13.04 to support Stratos, and to also automate the setup of the Stratos runtime.  This environment can also setup a local Openstack environment for those users who want minimal configuration of an IaaS to try out Stratos.

**WARNING:** This environment is a work-in-progress.  When it is ready for public use, a github release will be created.

#### Pre-requisites

This environment uses Vagrant [(download)](http://www.vagrantup.com/downloads.html) and Virtualbox [(download)](https://www.virtualbox.org/wiki/Downloads).

**WARNING:** Make sure you install Vagrant from the above link and not your distribution's vagrant package.

Tested with:

- Vagrant 1.4.2
- Virtualbox 4.3.8r92456

#### Quick Start

To setup stratos and openstack:

- Clone this project: ```git clone git@github.com:snowch/devcloud-script.git```
- Change into the project directory: ```cd devcloud-script```
- Setup Stratos and Openstack: ```vagrant destroy -f && vagrant up && vagrant ssh -c "./stratos_dev.sh -f" && vagrant ssh -c "./openstack-qemu.sh -f"```.  This command:
  - Configures a puppet master
  - Checks out stratos
  - Builds Stratos
  - Installs Stratos
  - Sets up Openstack
  - Creates a Cartridge
- Access Stratos Console: https://192.168.56.5:9443/console - admin/admin
- Access Openstack Console: http://192.168.92.30 - admin/g

#### Issues

- This environments will not work if you access the internet through a Proxy (transparent proxies should be ok).

### Stratos Development Environment

You can also setup a Stratos development environment with eclipse.

Ssh into your Stratos Runtime Environment and run this command:

 - ```./stratos_dev.sh -d``` # sets up ubuntu desktop + eclipse and imports Stratos source code

Login to your development environment using rdesktop (*nix) or Remote Desktop Connection (windows):

 - Host: 192.168.56.5
 - Port: 3389
 - Username: vagrant
 - Password: vagrant
