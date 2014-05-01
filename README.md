## Stratos Runtime and Development Environments 

### Stratos Runtime Environment

#### Overview

This project contains scripts to automate the setup of Ubuntu 13.10 to support Stratos, and to also automate the setup of puppet and the Stratos runtime.  This environment can also setup a local Openstack environment for those users who want minimal configuration of an IaaS to try out Stratos.

#### Pre-requisites

This environment uses Vagrant [(download)](http://www.vagrantup.com/downloads.html) and Virtualbox [(download)](https://www.virtualbox.org/wiki/Downloads).

**WARNING:** Make sure you install Vagrant from the above link and not your distribution's vagrant package.

Tested with:

- Vagrant 1.4.2
- Virtualbox 4.3.8r92456
- At least 5Gb free memory

#### Quick Start

To setup stratos and openstack:

- Install Vagrant using the above link
- Install Virtualbox using the above link
- Clone this project: ```git clone git@github.com:snowch/stratos-vagrant-box.git```
- Change into the project directory: ```cd stratos-vagrant-box```
- Run ```./new_statos_and_openstack_docker.sh```
- Access Stratos Console: https://192.168.56.5:9443/console - admin/admin
- Access Openstack Console: http://192.168.92.30 - admin/g
- See stratos.log for Stratos and Openstack setup output
- See test.log for basic provisioning output

#### Stratos Version

The environment checks out and builds ```4.0.0-incubating``` version. If you want to change the version:

- ```cp stratos_version.conf.example stratos_version.conf```
- Edit the ```STRATOS_SRC_VERSION``` value (e.g. master)

#### Issues

- This environment will not work if you access the internet through a Proxy (transparent proxies should be ok).

