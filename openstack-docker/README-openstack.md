vagrant destroy -f && \
vagrant up && \
vagrant ssh -c "./openstack.sh -f" && \
vagrant reload && \
vagrant ssh -c "./openstack.sh -f"
