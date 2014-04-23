## Stratos Runtime and Development Environments 

### Stratos Runtime Environment

#### Overview

This project contains scripts to automate the setup of Ubuntu 13.04 to support Stratos, and to also automate the setup of puppet and the Stratos runtime.  This environment can also setup a local Openstack environment for those users who want minimal configuration of an IaaS to try out Stratos.

#### Pre-requisites

This environment uses Vagrant [(download)](http://www.vagrantup.com/downloads.html) and Virtualbox [(download)](https://www.virtualbox.org/wiki/Downloads).

**WARNING:** Make sure you install Vagrant from the above link and not your distribution's vagrant package.

Tested with:

- Vagrant 1.4.2
- Virtualbox 4.3.8r92456

#### Quick Start

To setup stratos and openstack:

- Install Vagrant using the above link
- Install Virtualbox using the above link
- Clone this project: ```git clone git@github.com:snowch/devcloud-script.git```
- Change into the project directory: ```cd devcloud-script```
- Run either:
  - ```./vagrant_developer_env_setup.sh``` (unix/cygwin)
  - ```vagrant_developer_env_setup.bat``` (windows)
- Access Stratos Console: https://192.168.56.5:9443/console - admin/admin
- Access Openstack Console: http://192.168.92.30 - admin/g
- Login to your development environment using rdesktop (*nix) or Remote Desktop Connection (windows):
 - Host: 192.168.56.5
 - Port: 3389
 - Username: vagrant
 - Password: vagrant

#### Issues

- This environment will not work if you access the internet through a Proxy (transparent proxies should be ok).

