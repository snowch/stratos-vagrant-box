#!/bin/bash 

set -e # exit on error

sudo apt-get install -y libgdbm-dev libncurses5-dev automake libtool bison libffi-dev curl git
curl -L https://get.rvm.io | bash -s stable
source ~/.rvm/scripts/rvm
echo "source ~/.rvm/scripts/rvm" >> ~/.bashrc
rvm install 2.1.2
gem install bundle
cd /vagrant/plugin/
bundle exec rake build
