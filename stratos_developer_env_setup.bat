
vagrant destroy -f && vagrant up && vagrant ssh -c "./stratos.sh -f && ./stratos.sh -d && ./openstack-qemu.sh -f"
