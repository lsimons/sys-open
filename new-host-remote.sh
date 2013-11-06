#!/usr/bin/env bash

# This script is invoked from new-host.sh to set up a new machine.
# It's designed to be re-runnable safely.

set -e

MASTER=$1
FQLN=$2
IP=`ifconfig  | grep 'inet addr:'| grep -v '127.0.0.1' | cut -d: -f2 | egrep -v '^10\.' | egrep -v '^192\.168\.' | awk '{ print $1}'`

[[ -n "${MASTER}" ]] || (echo "Puppet master IP not provided"; exit 1)
[[ -n "${FQLN}" ]] || (echo "Local name not provided"; exit 1)
[[ -n "${IP}" ]] || (echo "Cannot determine IP address"; exit 1)

# check hostname matches FQLN
me=`hostname`
[[ "${FQLN}" == "${me}" ]] || (echo "My name is ${me}, not ${FQLN}, please fix me"; exit 1)

# DO NOT install puppetlabs puppet repo
# (if this needs doing it'll be done by puppet)
#   echo -e "deb http://apt.puppetlabs.com/ lucid main\ndeb-src http://apt.puppetlabs.com/ lucid main" >> /etc/apt/sources.list.d/puppet.list
#   apt-key adv --keyserver keyserver.ubuntu.com --recv 4BD6EC30
#   wget http://apt.puppetlabs.com/puppetlabs-release-precise.deb || exit 1
#   dpkg -i puppetlabs-release-precise.deb || exit 1

apt-get update

# patch to latest LTS
apt-get dist-upgrade -y

# set puppet hostname to point to master
puppet_known="cat /etc/hosts | grep puppet"
if [[ -n "$puppet_known" ]]; then
    apt-get install -y augeas-tools
    echo -e "set /files/etc/hosts/01/ipaddr ${MASTER}\nset /files/etc/hosts/01/canonical puppet\nsave" | augtool
fi

# install puppet
#apt-get install -y ruby1.8 libaugeas-ruby1.8 libshadow-ruby1.8 facter
#apt-get install -y ruby
apt-get install -y puppet puppet-common 

cat > /etc/default/puppet <<END
# Defaults for puppet - sourced by /etc/init.d/puppet 
# Start puppet on boot? 
START=yes

# Startup options 
DAEMON_OPTS=""
END

puppet agent -t || true
echo "Above error about cert is ignorable"

echo -e "Now do \n  ssh root@${MASTER} puppet cert list\n  ssh root@${MASTER} puppet cert sign ${FQLN}\n\nThen hit enter to continue"
read foo

puppet agent -t

echo
echo "Ok, I hope that worked...check the logs above '(-_-) ..."
echo
echo "You should reboot to update the kernel to the latest version"
echo
