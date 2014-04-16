Stratos Runtime and Development Environments 
============================================

[![Build Status](https://travis-ci.org/snowch/devcloud-script.png?branch=master)](https://travis-ci.org/snowch/devcloud-script)


## Stratos Runtime Environment

### Overview

This project contains scripts to automate the setup of Ubuntu 12.04 to support Stratos, and to also automate the setup of the Stratos runtime.  

This environment also provides a local Cloudstack vagrant environment for those users who want minimal configuration of an IaaS to try out Stratos.

**WARNING:** This environment is a work-in-progress.  When it is ready for public use, a github release will be created.

### Pre-requisites

This environment uses Vagrant [(download)](http://www.vagrantup.com/downloads.html) and Virtualbox [(download)](https://www.virtualbox.org/wiki/Downloads).

Tested with:

- Vagrant 1.4.2
- Virtualbox 4.3.8r92456

### Usage

- Clone this project: ```git clone git@github.com:snowch/devcloud-script.git && cd devcloud-script```
- If you want to use setup a local cloudstack environment for running stratos, see the section "Cloudstack Runtime", below.
- Configure and start the "Stratos Runtime", see below.

#### Stratos Runtime ####

- Start and Provision **Stratos** box:

 - Edit the iaas.conf to point to your IaaS (only AWS is supported at the moment)
 - ```vagrant up stratos``` # starts the stratos box
 - ```vagrant provision stratos``` # copy the setup script to the guest
 - ```vagrant ssh stratos``` # log in to the stratos box
 - ```./stratos_dev.sh -h``` # show the stratos setup instructions


#### Cloudstack Runtime ####

See [Cloudstack README](./README-cloudstack.md)

### Todo

- The final step of connecting Stratos to an IaaS has yet to be done!

### Issues

- Proxy setup has not been tested or documented


## Stratos Development Environment

Ssh into your Stratos Runtime Environment and run this command:

 - ```./stratos_dev.sh -d``` # sets up ubuntu desktop + eclipse and imports Stratos source code

Login to your development environment using rdesktop (*nix) or Remote Desktop Connection (windows):

 - Host: 192.168.56.5
 - Port: 3389
 - Username: vagrant
 - Password: vagrant
