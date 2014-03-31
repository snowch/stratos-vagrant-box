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
