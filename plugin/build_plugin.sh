#!/bin/bash 

set -e # exit on error

cd /vagrant/plugin/
bundle exec rake build
