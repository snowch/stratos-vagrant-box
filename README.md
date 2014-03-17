Stratos + Cloudstack Environment
================================

### Overview

This project contains scripts to provision cloudstack and stratos runtimes.

**WARNING:** This environment is a work-in-progress.  When it is ready for public use, a github release will be created.

### Usage

- Clone this project: ```git clone git@github.com:snowch/devcloud-script.git  & cd devcloud-script```

- Start and Provision **Cloudstack** box:

 - ```vagrant up cloudstack``` # starts the cloudstack box
 - ```vagrant provision cloudstack``` # this increases the xen kernel memory and reboots
 - ```vagrant provision cloudstack``` # this checks out, builds, runs and provisions cloudstack. 
 - ```vagrant ssh cloudstack``` # log in to the cloudstack box
 - ```./cloudstack_dev.sh -r``` # runs cloudstack

Now open a browser from your host to 'http://192.168.56.10:8080/client' and login with 'admin/password'.  You should be able to create an instance (don't attach storage to the image - this isn't working).

- Start and Provision **Stratos** box:

 - ```vagrant up stratos``` # starts the stratos box
 - ```vagrant ssh stratos``` # log in to the stratos box
 - ```./stratos_dev.sh -i``` # this sets up stratos as per [Stratos Wiki]( https://cwiki.apache.org/confluence/display/STRATOS/4.0.0+Installation+Guide)


### Issues

- Proxy setup has not been tested or documented
- Cloudstack image storage does not work
