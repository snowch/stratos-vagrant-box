#!/bin/bash 

set -e # exit on error

cd /vagrant/plugin/
source ~/.rvm/scripts/rvm
bundle install # checks out vagrant gem
bundle exec rake test
bundle exec rake build
