#!/bin/bash

set -e
set -x

MASTER=manage01.local
BOOTSTRAP=${BOOTSTRAP:-}
MACHINE=${1:-${MASTER}}


rsync -av --delete ./ root@$MASTER:/etc/sys/ \
    --exclude=.git \
    --exclude=wordpress \
    --exclude=puppet/modules/common/pki/files \
    --exclude=puppet/modules/common/nagios/files/nagios3/conf.d/*.local.cfg \
    --exclude=puppet/modules/common/mail/files/relay_clientcerts \
    --exclude=htpasswd \
    --include=puppet/modules/common/apt/files/rackspace_backup.{key,list} \
    --exclude=puppet/modules/common/apt/files/*.{list,gpg,key} \
    --exclude=puppet/modules/common/apt/files/00securerepo
    

if [[ "${MACHINE}" == "all" ]]; then
    ssh root@manage01.local "/usr/bin/puppet agent -t"
    ssh root@log01.local "/usr/bin/puppet agent -t"
    ssh root@mail01.local "/usr/bin/puppet agent -t"
    ssh root@backup01.local "/usr/bin/puppet agent -t"
    
    ssh root@svc01.local "/usr/bin/puppet agent -t"
    ssh root@svc02.local "/usr/bin/puppet agent -t"
    ssh root@svc03.local "/usr/bin/puppet agent -t"
    
    ssh root@monitor01.local "/usr/bin/puppet agent -t"
elif [[ "x${BOOTSTRAP}" != "x" ]]; then
    ssh root@$MASTER /bin/bash /etc/sys/setup-puppetmaster.sh
    if [[ $MACHINE != $MASTER ]]; then
        ssh root@$MACHINE "/usr/bin/puppet agent -t"
    fi
else
    ssh root@$MASTER "/usr/bin/puppet master --compile $MACHINE >/dev/null"
    ssh root@$MASTER "rm -f /var/lib/puppet/yaml/node/$MACHINE* >/dev/null"
    ssh root@$MACHINE "/usr/bin/puppet agent -t"
fi
