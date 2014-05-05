echo "Destroying previous virtual machines"
vagrant destroy -f 

echo "Starting new virtual machine"
vagrant up 

echo "Starting Stratos setup"
vagrant ssh -c "./stratos.sh -f"

echo "Setting up Lubuntu desktop and eclipse"
vagrant ssh -c "./stratos.sh -d"

echo "Setting up kernel for Docker"
vagrant ssh -c "./openstack-docker.sh -o" 

echo "Rebooting after new kernel installation"
vagrant reload 

echo "Setting up docker"
vagrant ssh -c "./openstack-docker.sh -o && ./openstack-docker.sh -d"

echo "Strating stratos"
vagrant ssh -c "./stratos.sh -s && sleep 5m" 

echo "Testing stratos"
vagrant ssh -c ". /vagrant/tests/test_stratos.sh" 

