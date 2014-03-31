#### Cloudstack Runtime ####

##### Setup **Cloudstack** box:

Get the cloudstack box:
```vagrant box add cloudstack-vagrant-box https://github.com/snowch/cloudstack-vagrant-box/releases/download/v0.1/devcloud.box```

Start up the box:
```vagrant up cloudstack```

SSH into the box:
```vagrant ssh cloudstack```

Checkout, build and setup cloudstack (this step will take a long time!):
```./cloudstack.sh -i```

Run Cloudstack:
```./cloudstack.sh -r```

Use Cloudstack:

When cloudstack is running, open a browser from your host to 'http://192.168.56.10:8080/client' and login with 'admin/password'. After logging in, check "Infrastructure > System VMs".  When the VM State shows "Running" and Agent State shows "Up" for both VMs, you should be able to create an instance.  If you don't see a template when creating an instance, wait a few minutes because cloudstack is probably still setting it self up in the background.

Shutdown the box:
 ```vagrant halt cloudstack```
 
##### Subsequent runs

On subsequent, after ```vagrant up```, exectute ```./cloudstack.sh -r```.
