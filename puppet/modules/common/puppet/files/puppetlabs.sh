#!/bin/bash

# toggles the puppetlabs repo on and off

if [[ $1 == "on" ]]; then
    set -x
    # puppet 3.2+ needs puppetlabs-release > 1.0.7 to upgrade from 3.0/3.1
    #dpkg -s puppetlabs-release | grep 'Status: install' > /dev/null
    #if [[ $? -eq 0 ]]; then
    #    echo "already installed"
    #else
        echo -e "deb http://apt.puppetlabs.com/ lucid main\ndeb-src http://apt.puppetlabs.com/ lucid main\ndeb http://apt.puppetlabs.com lucid dependencies\ndeb-src http://apt.puppetlabs.com lucid dependencies" > /etc/apt/sources.list.d/puppet.list
        apt-key adv --keyserver keyserver.ubuntu.com --recv 4BD6EC30
        apt-get -qq -y update
        apt-get -qq -y clean
        apt-get -qq -y install puppetlabs-release
        rm /etc/apt/sources.list.d/puppet.list
    #fi
    exit 0
elif [[ $1 == "off" ]]; then
    set -x
    apt-get -qq -y remove puppetlabs-release -y
    rm /etc/apt/sources.list.d/puppet.list
    apt-get -qq -y update
    apt-get -qq -y clean
    exit 0
else
    echo "Usage: $0 <on|off>"
    exit 1
fi
