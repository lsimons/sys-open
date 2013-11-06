#!/bin/bash
# PUPPET
# Simple test to see if a reboot is required (on an Ubuntu 12.04 machine).


# The test is based on the following assumption: 
# If there is a newer kernel available in /boot than the kernel that is
# currently running: the machine will need a reboot.


LATEST_KERNEL="`ls /boot/vmlinuz-* | sort -n | tail -n 1 | sed -e 's/.*vmlinuz-//g'`"
CURRENT_KERNEL="`uname -r`"

if ! [ ${LATEST_KERNEL} == ${CURRENT_KERNEL} ] ; then
  echo Reboot required to switch from ${CURRENT_KERNEL} to ${LATEST_KERNEL}.
else 
  echo Running latest kernel ${CURRENT_KERNEL}.
fi

exit 0 
