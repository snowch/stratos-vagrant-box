Stratos + Cloudstack Environment
================================

### Overview

This project contains scripts to provision cloudstack and stratos runtimes.

### Usage

- Clone this project: ```git clone git@github.com:snowch/devcloud-script.git  & cd devcloud-script```

- Start and Provision **Cloudstack** box:

 - ```vagrant up cloudstack``` # starts the cloudstack box
 - ```vagrant provision cloudstack``` # this increases the xen kernel memory and reboots
 - ```vagrant provision cloudstack``` # this checks out, builds, runs and provisions cloudstack. 
 - ```vagrant ssh cloudstack``` # log in to the cloudstack box
 - ```./cloudstack_dev.sh -r``` # runs cloudstack

- Start and Provision **Stratos** box:

 - ```vagrant up stratos``` # starts the stratos box
 - ```vagrant ssh stratos``` # log in to the stratos box
 - ```./stratos_dev.sh -i``` # this sets up stratos as per [Stratos Wiki]( https://cwiki.apache.org/confluence/display/STRATOS/4.0.0+Installation+Guide)


### Issues

- Proxy setup has not been tested or documented
