
vagrant destroy -f && vagrant up && vagrant ssh -c "./stratos_dev.sh -f && ./openstack-qemu.sh -f"
