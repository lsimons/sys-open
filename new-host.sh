#!/usr/bin/env bash

# This script copies new-host-remote.sh to a new machine and runs it there.
# It's designed to be re-runnable safely.
# You'll probably have to enter the root password for the machine, twice.
#
# To use:
#      ./new_host.sh svcXX lonrs dev
# Or to use locally:
#      FQDN=monitor01.local MASTER=172.16.88.10 DOMAIN=local ./new-host.sh monitor01 local local \
#        ./new_host.sh svcXX local local

set -e
set -x

MASTER=${MASTER:-31.222.191.10}
DOMAIN=${DOMAIN:-example.org}
MACHINE=$1
DATACENTER=$2
ENVIRONMENT=$3

FQDN=${FQDN:-${MACHINE}.${DATACENTER}.${ENVIRONMENT}.${DOMAIN}}

usage() {
    echo "usage: ./new-host.sh machine datacenter environment"
    exit 1
}

[[ -n "${MACHINE}" ]] || usage
[[ -n "${DATACENTER}" ]] || usage
[[ -n "${ENVIRONMENT}" ]] || usage

scp new-host-remote.sh root@${FQDN}:/root/
ssh root@${FQDN} /root/new-host-remote.sh ${MASTER} ${FQDN}
