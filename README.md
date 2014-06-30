## Stratos Runtime and Development Environments 

### Stratos Runtime Environment

#### Overview

This project contains scripts to automate the setup of Ubuntu 13.04 to support Stratos, and to also automate the setup of puppet and the Stratos runtime.  This environment can also setup a local Openstack environment for those users who want minimal configuration of an IaaS to try out Stratos.

#### Pre-requisites

This environment uses Vagrant [(download)](http://www.vagrantup.com/downloads.html) and Virtualbox [(download)](https://www.virtualbox.org/wiki/Downloads).

**WARNING:** Make sure you install Vagrant from the above link and not your distribution's vagrant package.

- The host machine must:
  - not be a virtual machine
  - be an OS supported by Vagrant and Virtualbox (Linux, OS X, Windows)
  - have at least 5Gb free memory
  - have 64 bit architecture

Tested with:

- Vagrant 1.6.2
- Virtualbox 4.3.8r92456

#### Quick Start

To setup stratos and openstack:

- Install Vagrant using the above link
- Install Virtualbox using the above link
- Clone this project: ```git clone git@github.com:snowch/stratos-vagrant-box.git```
- Change into the project directory: ```cd stratos-vagrant-box```
- Execute the command: ```vagrant plugin install plugin/pkg/stratos-x.y.z.gem``` (replace x.y.z with the actual version)
- Execute the command: ```vagrant stratos --help``` 
- Follow the instructions printed by help

#### Stratos Version

The environment checks out and builds ```4.0.0``` version. If you want to change the version:

- ```cp stratos_version.conf.example stratos_version.conf```
- Edit the ```STRATOS_SRC_VERSION``` value (e.g. master)

#### Issues

- This environment will not work if you access the internet through a Proxy (transparent proxies should be ok).
- See github [issues page](https://github.com/snowch/stratos-vagrant-box/issues) for a list of known issues.

