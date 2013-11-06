#!/bin/bash
# PUPPET
# Simple test to see if there are updates available. Use by calling from snmpd.
# Need to add this as an exec or sh or extend to snmpd.conf first! And restart
# snmpd.

# from http://superuser.com/a/199874

# Query pending updates.
updates=$(/usr/lib/update-notifier/apt-check 2>&1)
status=$?
if [ $status -ne 0 ]; then
    echo "Querying pending updates failed with exit code $status: $updates"
    exit 0
fi

# Check for the case where there are no updates.
if [ "$updates" = "0;0" ]; then
    echo "All packages are up-to-date."
    exit 0
fi;

# Check for pending security updates.
pending=$(echo "$updates" | cut -d ";" -f 2)
if [ "$pending" != "0" ]; then
    echo "$pending security update(s) pending."
    exit 0
fi

# Check for pending non-security updates.
pending=$(echo "$updates" | cut -d ";" -f 1)
if [ "$pending" != "0" ]; then
    echo "$pending non-security update(s) pending."
    exit 0
fi

# If we've gotten here, we did something wrong since our "0;0" check should have
# matched at the very least.
echo "Script failed, manual intervention required."
exit 0
