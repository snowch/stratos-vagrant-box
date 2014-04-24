
vagrant destroy -f && vagrant up && vagrant ssh -c "./stratos_dev.sh -f && ./stratos_dev.sh -d && ./openstack-qemu.sh -f"
