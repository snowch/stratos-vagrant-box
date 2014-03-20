Stratos Runtime Environment
===========================

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

- Clone this project: ```git clone git@github.com:snowch/devcloud-script.git  & cd devcloud-script```
- If you want to use setup a local cloudstack environment for running stratos, see the section "Cloudstack Runtime", below.
- Configure and start the "Stratos Runtime", see below.

#### Stratos Runtime ####

- Start and Provision **Stratos** box:

 - Edit the iaas.conf to point to your IaaS
 - ```vagrant up stratos``` # starts the stratos box
 - ```vagrant ssh stratos``` # log in to the stratos box
 - ```./stratos_dev.sh -h``` # show the stratos setup instructions


#### Cloudstack Runtime ####

- Setup **Cloudstack** box:

 - ```vagrant up cloudstack``` # starts the cloudstack box
 - ```ACTION='setup-cloudstack' vagrant provision cloudstack``` # setup-cloudstack action first increases the xen kernel memory and reboots
 - ```ACTION='setup-cloudstack' vagrant provision cloudstack``` # setup-cloudstack action subsequent run checks out, builds, runs and provisions cloudstack. 
 - ```vagrant halt cloudstack``` # stop the cloudstack box when finished using it

- Run **Cloudstack** box

 - ```vagrant up cloudstack``` # starts the cloudstack box
 - ```vagrant reload cloudstack && ACTION='run-cloudstack' vagrant provision cloudstack``` # this runs cloudstack
 - ```vagrant halt cloudstack``` # stop the cloudstack box when finished using it

When cloudstack is running, open a browser from your host to 'http://192.168.56.10:8080/client' and login with 'admin/password'. After logging in, check "Infrastructure > System VMs".  When the VM State shows "Running" and Agent State shows "Up" for both VMs, you should be able to create an instance.  If you don't see a template when creating an instance, wait a few minutes because cloudstack is probably still setting it self up in the background.

### Todo

- The final step of connecting Stratos to an IaaS has yet to be done!
- Create a packer build with appropriate size XEN kernel or move to a non-Xen cloudstack environment such as [simstack](https://github.com/runseb/simstack)

### Issues

- Proxy setup has not been tested or documented
