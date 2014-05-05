echo "Destroying previous virtual machines"
vagrant destroy -f 

echo "Starting new virtual machine"
vagrant up 

echo "Starting Stratos setup"
vagrant ssh -c "./stratos.sh -f"

echo "Setting up kernel for Docker"
vagrant ssh -c "./openstack-docker.sh -o" 

echo "Rebooting after new kernel installation"
vagrant reload 

echo "Setting up docker"
vagrant ssh -c "./openstack-docker.sh -o && ./openstack-docker.sh -d" 

# start stratos
echo "Starting Stratos"
vagrant ssh -c "./stratos.sh -s && sleep 5m" 

echo "Testing Stratos"
vagrant ssh -c ". /vagrant/tests/test_stratos.sh" 

