#!/bin/bash

set -x

# This is a simple bootstrap script that configures a fresh Ubuntu 10.04 LTS VM on rackspace as a puppet mater
#
# copy it onto the new machine and then run it:
#
#   scp setup-puppetmaster.sh root@${MYNEWMACHINE}:/root/
#   ssh root@${MYNEWMACHINE} /root/setup-puppetmaster.sh

# name the local machine as the puppet master

# get interfaces that are not local
# then filter out interfaces that are private 10.x, 192.x, etc
# we now believe we are left with exactly one ip address
IP=`ifconfig  | grep 'inet addr:'| grep -v '127.0.0.1' | cut -d: -f2 | egrep -v '^10\.' | egrep -v '^192\.168\.' | awk '{ print $1}'`
apt-get install -y augeas-tools || exit 1
# find the hosts entry for that ip address
# host=`augtool match /files/etc/hosts/*/ipaddr $IP | sed s'/\/ipaddr//'`
# add a new alias for that hosts entry
grep puppet /etc/hosts > /dev/null
[[ $? -eq 0 ]] || echo -e "defnode newnode /files/etc/hosts/2/alias[last()+1] puppet\nsave" | augtool -e

# use puppetlabs repo to get recent puppet version
#   (this may very well be downgraded later by the puppet configuration...)
# dpkg -l | grep puppetlabs-release > /dev/null
# if [[ $? -eq 1 ]]; then
#     echo -e "deb http://apt.puppetlabs.com/ lucid main\ndeb-src http://apt.puppetlabs.com/ lucid main" >> /etc/apt/sources.list.d/puppet.list
#     apt-key adv --keyserver keyserver.ubuntu.com --recv 4BD6EC30
#     apt-get update -qq
#     apt-get install puppetlabs-release
#     rm /etc/apt/sources.list.d/puppet.list
# fi
apt-get update -qq

# set up ssh for use with github
if ! [ -d /root/.ssh ] ; then
    mkdir /root/.ssh
    chmod 700 /root/.ssh
fi
grep github.com /root/.ssh/known_hosts > /dev/null
[[ $? -eq 0 ]] || ssh-keyscan github.com >> /root/.ssh/known_hosts

if [[ ! -f /root/.ssh/id_rsa ]]; then
    ssh-keygen -f /root/.ssh/id_rsa  -N "" -P ""
    echo Key:
    echo /root/.ssh/id_rsa.pub
    echo "Now add the Above ssh key to github and then hit enter to continue"
    read foo
fi

# set up git and checkout /etc/sys
apt-get install -y git-core git-doc || exit 1

cd /etc/ || exit 1
if [ -d sys ] ; then
    cd sys
    git pull
    cd ..
else
    git clone git@github.com:OldExample/sys.git sys || exit 1
fi

[[ -d /etc/puppet ]] || mkdir -p /etc/puppet
cd /etc/puppet/ || exit 1

cp puppet.conf puppet.conf.bak
cp /etc/sys/puppet/modules/common/puppet/files/puppet.bootstrap.conf puppet.conf || exit 1

cd ~

# install puppet
apt-get install -y ruby1.8 libaugeas-ruby1.8 libshadow-ruby1.8 facter
apt-get install -y ruby
apt-get install -y puppet || exit 1

/etc/init.d/puppet stop
cat > /etc/default/puppet <<END
# Defaults for puppet - sourced by /etc/init.d/puppet 
# Start puppet on boot? 
START=no

# Startup options 
DAEMON_OPTS=""
END

# install puppetmaster, which picks up the git config we checked out
#puppet apply --debug --modulepath=/etc/sys/puppet/modules/common /etc/sys/puppet/modules/common/puppetmaster/manifests/init.pp
apt-get install puppetmaster -y || exit 1

# bootstrap done, apply the puppet config to further self-config
puppet agent -t
