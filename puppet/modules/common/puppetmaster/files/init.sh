#!/bin/bash
#PUPPET

# I use this on my VirtualBox environment to quickly bootstrap a new puppet
# node. 
# This file is fetched on a fresh ubuntu 12.04 at boottime. It can be run
# multiple times and does absolutely 0 (=zero) error checking. 
# Do not use in production.



mv /var/tmp/init.sh /var/tmp/init.sh.running

# Exit if puppet is already installed
which puppet && exit 0

deluser ubuntu
delgroup ubuntu

PUPPET_NAME=REPLACEME_PUPPETNAME
IP=REPLACEME_IP
DNS=REPLACEME_DNS

# If no name was set, create one:
if [[ $PUPPET_NAME == "REPLACEME_PUPPETNAME" ]] ; then
  PUPPET_NAME="pup`date +%s`"
fi

if ! [[ $IP == "REPLACEME_IP" ]] ; then
  cat > /etc/network/interfaces <<END_OF_INTERFACES
# The loopback network interface
auto lo
iface lo inet loopback

# The primary network interface
auto eth0
iface eth0 inet dhcp


auto eth1
iface eth1 inet static
  address ${IP}
  netmask 255.255.255.0

END_OF_INTERFACES
fi

cat > /etc/apt/sources.list <<END_OF_SOURCES
deb http://de.archive.ubuntu.com/ubuntu/ precise main restricted
deb http://de.archive.ubuntu.com/ubuntu/ precise-updates main restricted
deb http://de.archive.ubuntu.com/ubuntu/ precise universe
deb http://de.archive.ubuntu.com/ubuntu/ precise-updates universe
deb http://de.archive.ubuntu.com/ubuntu/ precise multiverse
deb http://de.archive.ubuntu.com/ubuntu/ precise-updates multiverse
deb http://de.archive.ubuntu.com/ubuntu/ precise-backports main restricted universe multiverse
deb http://security.ubuntu.com/ubuntu precise-security main restricted
deb http://security.ubuntu.com/ubuntu precise-security universe
deb http://security.ubuntu.com/ubuntu precise-security multiverse

END_OF_SOURCES

echo nameserver ${DNS} >> /etc/resolvconf/resolv.conf.d/head
echo ${PUPPET_NAME} > /etc/hostname
hostname ${PUPPET_NAME}
service networking restart
service networking restart

service resolvconf  restart
/etc/init.d/hostname start

# install puppetlabs puppet repo
echo -e "deb http://apt.puppetlabs.com/ precise main\ndeb-src http://apt.puppetlabs.com/ precise main" >> /etc/apt/sources.list.d/puppet.list
apt-key adv --keyserver keyserver.ubuntu.com --recv 4BD6EC30
apt-get update || exit 1
apt-get install puppetlabs-release || exit 1
rm /etc/apt/sources.list.d/puppet.list
apt-get update || exit 1
#apt-get dist-upgrade -y
# install puppet
apt-get install -y ruby1.8 libaugeas-ruby1.8 libshadow-ruby1.8 facter
apt-get install -y ruby || exit 1
#apt-get install -y puppet
apt-get install -y puppet=2.7.19-1puppetlabs2 puppet-common=2.7.19-1puppetlabs2 || exit 1


cat > /etc/default/puppet <<END
# Defaults for puppet - sourced by /etc/init.d/puppet 
# Start puppet on boot? 
START=yes

# Startup options 
DAEMON_OPTS=""
END
puppet agent --test
mv /var/tmp/init.sh.running /var/tmp/init.sh.ran
reboot
exit 0
