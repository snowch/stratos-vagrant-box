@echo off

DEL /F stratos.log
IF ERRORLEVEL 1 (
   echo "Couldn't delete 'stratos.log'. Ensure that vagrant isn't running (ruby.exe)"
   EXIT /b %errorlevel%
)

echo "Destroying previous virtual machines"
vagrant destroy -f > stratos.log 2>&1
IF ERRORLEVEL 1 (
   echo "There was an error running 'vagrant destroy -f'"
   EXIT /b %errorlevel%
)

echo "Starting new virtual machine"
vagrant up >> stratos.log 2>&1
IF ERRORLEVEL 1 (
   echo "There was an error running 'vagrant up'"
   EXIT /b %errorlevel%
)

echo "Starting Stratos setup"
vagrant ssh -c "./stratos.sh -f" >> stratos.log 2>&1
IF ERRORLEVEL 1 (
   echo "There was an error running 'vagrant ssh -c "./stratos.sh -f"'"
   EXIT /b %errorlevel%
)

echo "Starting Stratos Development Environment setup"
vagrant ssh -c "./stratos.sh -d" >> stratos.log 2>&1
IF ERRORLEVEL 1 (
   echo "There was an error running 'vagrant ssh -c "./stratos.sh -d"'"
   EXIT /b %errorlevel%
)

echo "Setting up kernel for Docker"
vagrant ssh -c "./openstack-docker.sh -o" >> stratos.log 2>&1
IF ERRORLEVEL 1 (
   echo "There was an error running 'vagrant ssh -c "./openstack-docker.sh -o"'"
   EXIT /b %errorlevel%
)

echo "Rebooting after new kernel installation"
vagrant reload >> stratos.log 2>&1
IF ERRORLEVEL 1 (
   echo "There was an error running 'vagrant reload'"
   EXIT /b %errorlevel%
)

echo "Setting up docker"
vagrant ssh -c "./openstack-docker.sh -o && ./openstack-docker.sh -d" >> stratos.log 2>&1
IF ERRORLEVEL 1 (
   EXIT /b %errorlevel%
)

# start stratos
echo "Starting Stratos"
vagrant ssh -c "./stratos.sh -s && sleep 5m" >> stratos.log 2>&1
IF ERRORLEVEL 1 (
   echo "There was a problem running 'vagrant ssh -c "./stratos.sh -s && sleep 5m"'"
   EXIT /b %errorlevel%
)

echo "Testing Stratos"
vagrant ssh -c ". /vagrant/tests/test_stratos.sh" >> stratos.log 2>&1
IF ERRORLEVEL 1 (
   echo "There was a problem running 'vagrant ssh -c "./vagrant/tests/test_stratos.sh"'"
   EXIT /b %errorlevel%
)
