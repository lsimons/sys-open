#!/usr/bin/env bash

# Updates puppet config on master, then forces immediate update on any specified servers
# For example
#    ./puppet-update.sh
#       (running puppet agents will pick up changes in 30 mins)
#    ./puppet-update.sh svc{01,02,03,04}.lonrs.test.local
#       (running puppet agents will pick up changes in 30 mins, the specified machines will pick it up now)
# this is a stupid for loop around SSH, you'd be welcome to get rid of it in favor of a proper puppet kick or similar

set -e
set -x

MASTER=1.2.3.4
DOMAIN="example.org"

echo "NOTE: On ${MASTER} there's a cronjob that does a pull from github every 5 minutes."

ssh root@${MASTER} "(cd /etc/sys; git pull; puppet agent -t)" || true

for server in $@; do
    server=`echo $server | sed "s/.local/.${DOMAIN}/"`
    ssh manage@${server} sudo /usr/bin/puppet agent -t || true
done
