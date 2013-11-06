#!/usr/bin/ruby
#PUPPET 

# Original Source:
# https://raw.github.com/ripienaar/monitoring-scripts/master/puppet/check_puppet.rb

# Author: R.I. Pienaar (Volcane)

# mverwijs hacked this script to only output the number of seconds since last
# puppet ran. It can now be used as a snmp extension, providing a metric that
# Nagios can check against. 
# There is also the nasty fact that snmp runs as snmp, and can't read the
# puppet state file. Had to use the summaryfile instead.-20120918


# A simple nagios check that should be run as root
# perhaps under the mcollective NRPE plugin and
# can check when the last run was done of puppet.
# It can also check fail counts and skip machines
# that are not enabled
#
# The script will use the puppet last_run-summar.yaml
# file to determine when last Puppet ran else the age
# of the statefile.

require 'optparse'
require 'yaml'

lockfile = "/var/lib/puppet/state/puppetdlock"
statefile = "/var/lib/puppet/state/state.yaml"
summaryfile = "/var/log/puppet_lastran.log"
#summaryfile = "/var/lib/puppet/state/last_run_summary.yaml"
enabled = true
running = false
lastrun_failed = false
lastrun = 0
failcount = 0
warn = 0
crit = 0
enabled_only = false
failures = false

if File.exists?(lockfile)
    if File::Stat.new(lockfile).zero?
       enabled = false
    else
       running = true
    end
end

lastrun = File.stat(summaryfile).mtime.to_i if File.exists?(summaryfile)

rightnow = Time.now.to_i
time_since_last_run = rightnow - lastrun

unless failures
        puts "#{time_since_last_run}"
end
