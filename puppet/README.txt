
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!                                               !!
!!      THIS IS VERY MUCH A WORK IN PROGRESS!    !!
!!                                               !!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

=== Summary ===

The goal is to build a reproducable environment that provides a stable and
secure platform. On this platform we will build services for many different
customers and projects.

Meeting those goals require that certain consessions are made. One is a
severely limited scope of supported software. 

Wherever possible, PKI based security has been implemented, based on GNU-TLS. 

This document describes how to setup a production environment. It also
describes a best-practice on how to setup a development environment for
changing and testing the software that makes up most of the platform. 

As we aim not to be dependent on specific hardware or cloud providers it is
beyond the scope of this document to detail the setup of new
servers/nodes/virtual machines. For that we refer you to the documentation of
your platform provider (which is possibly you).

=== Target Audience ===

The target audience for this document is technical personnel. It is assumed
that the reader is an advanced Linux Administrator that is used to working on the
commandline and debugging Linux systems. FIXME

Specific software used:

* git
* puppet

=== Conventions ===

When we speak of 'machines', 'computers', 'nodes' it is assumed that they all
have the same meaning. And unless stated otherwise, these can be
either virtual or physiscal.

=== Platform Overview ===

In order to be able to copy/paste a computing infrastructure and apply it to
many different projects and situations the choice has been made to write the
implementation using the Puppet configuration management framework. For more
information on what Puppet is and does please see http://www.puppetlabs.com for
more information.

==== Overview ====

A production environment will always need several key components in order to
provide the services required. In no particular order, these components are:

* A management server that manages the configurations of all other machines.
* Secure messaging between servers and services requires a fully integrated
  PKI.
* A log server that receives and handles all logged data from all other
  machines.
* A backupserver that consolodates locally backed up data for further
  processing and safeguarding.
* A monitoring component for detecting anomalies and service loss.
* Email relaying for handling alerts.
* In order to provide tracable changes, we will be using a source control
  management system (SCM) that will track all the changes made to the
  configurations, scripts, templates and code that make up the platforms.



=== Implementation Choices ===

* Where possible we have chosen for standards, be it official, industry, or
  defacto. 
* Puppet was chosen as it is currently (2012) the defacto standard in
  cross-platform system-automation.
* Git was chosen as source control management system as it was not worse, nor
  better, than any of its competitors and it was already in use at
  Example. 
* For logging, rsyslog has been chosen as it has had native support for SSL
  certificates, as well as trigger-on-hit capabilities, allowing active
  monitoring should future implementations require that.
* For backups we're using automysqlbackup, autopostgresqlbackup and rdiff
  backup respectively.
* For extra cleverness, some puppet manifests will consult the puppetmaster for
  the information. Example: Nagios, PKI and Munin.

== Setting Up A Production Infrastructure ==

This section will describe how to setup a new production infrastructure. In
order to proceed, you must have (read) access to:

* The GitHub repository of Example Ops (or a clone thereof).

=== Set Up a PuppetMaster ===

The puppetmaster will function as the configuration management server and as
the Certificate Authority. 

After following these steps the following will be achieved:

* A new server will have a clone of the git-repository
  https://github.com/OldExample/sys.
* The clone will be placed in /etc/sys
* Puppetmaster (and puppet) will be installed and configured to read it's
  configurations from /etc/sys/puppet

NOTE: It is recommended that the Puppetmaster has a connection to the internet.
At least for the duration of the setup.

==== Installing the Software and Configs ====

Start up your new Ubuntu 12.04 LTS node that will function as puppetmaster.

After first boot-up log into the puppetmaster-node and become root.

Fetch the following file from GitHub and place it on the server:

 https://github.com/OldExample/sys/blob/master/setup-puppetmaster.sh

Make the file executable:
 
 chmod 700 setup-puppetmaster.sh

And execute it: 

 ./setup-puppetmaster.sh

This script will clone the entire Make the file executable:
 
 chmod 700 setup-puppetmaster.sh

And execute it: 

 ./setup-puppetmaster.sh

==== Make Puppetmaster Self-Aware ====

Puppet will configure all nodes. Including the puppetmaster.

FIXME: I think I should just write extensive commments in systems.yml and refer
to those here.

=== Set Up a Log Server ===

All targets are configured to send their logs to a central server. Here you
will configure that server. 

Add/Create a new server. Give


=== Set Up a Mail Server ===
=== Set Up a Backup Server ===
=== Set Up a ... ===
== Daily Tasks ==
=== Adding a new host ===
=== Changing any code. Any code at all. ===
=== Standard Development Cycle ===




=== Setup Puppet Development Environment ===

Rationale: As the goal is to create a repeatable, rapidly deployable production
environment it stands to reason that this is best achieved by also having a
repeatable and rapidly deployable development environment. 

NOTE: Why no cloud here? Clouds are slow. Fast clouds are costly. Your
development and testing routine will be significantly impacted by the lack of
IO, network connectivity or CPU power available in clouds. When building,
configuring and destroying VMs, speed is crucial.

First we'll outline the hardware you will need to run the development on. Then
we will discuss the virtualization software and its options. And last we will
start coding and applying that code to our new Virtual Env.

IMPORTANT: You need to have access to the "Example Sys" git repository in
order to use the documentation below. If you do not have that acces, please
contact Example in order to get that.

==== Hardware Requirements ====

In order to have a solid testing and development machine it is preferred you
have a physical machine that you have sole access to. Timesharing will cause
loss of productivity as most actions are resource hungry (I/O, network,
memory).

More hardware is better. For reference, my laptop has 4G memory and 120GB SSD
drive and carries a single 4 core i5 Intel processor.

==== Setup and Configuration ====

This is a walk-through on how to setup a machine that is able to quickly create
and destroy Virtual Machines. The goal is be able to start a coding session
with a fresh new environment that resembles production as closely as possible. 

==== Operating System ====

On your physical machine you will need to install Ubuntu LTS 12.04, either
Server or Desktop Edition. Any Ubuntu 12.04 derivative will do just fine as
well (Xubuntu, Kubuntu, Lubuntu...).

It is beyond the scope of this document to detail the installation.

===== Virtualization Software =====

Open a terminal and install VirtualBox: 

bq. sudo apt-get install virtualbox virtualbox-dkms virtualbox-fuse

In order to make it easier on you, add yourself to the fuser group. You may
have to logout and log in again before the changes take effect.

Assuming your username is 'ubuntu', the command would look like this:

bq. sudo adduser ubuntu fuse

Also add this line to /etc/fuse.conf:

bq. user_allow_other

===== Acquire Master Image =====

In order to create cloned images we need a master image to clone from.

For the sake of automation and speed I will use a Prebuilt VirtualBox Image
that was created by a third party. 

*IMPORTANT*: Do NOT use this image for production purposes as the quality is
untested.

The image can be downloaded from here:

bq. http://virtualboxes.org/images/ubuntu-server/

_NOTE_: The images available are available in 32bit only. Should you need 64bit
you will have to create one yourself (which is beyond the scope of this
document).

At the time of this writing, the download command is:

bq. wget "http://downloads.sourceforge.net/project/virtualboximage/UbuntuServer/12.04/ubuntu-12.04-server-i386.7z"

To use the file, you will first need to extract it. You will need p7zip to do
that: 

bq. sudo apt-get install p7zip-full

Now you can unpack:

bq. p7zip -d ubuntu-12.04-server-i386.7z 

If it does not exist, create the .VirtualBox folder in your home-directory:

bq. mkdir ~/.VirtualBox

Move the extracted folder into the .VirtualBox folder:

bq. mv ubuntu-12.04-server-i386/ .VirtualBox/

Now add the VM to VirtualBox:

bq. VBoxManage registervm ubuntu-12.04-server-i386/ubuntu-12.04-server-i386.vbox

If you now start VirtualBox, it should list the newly added Virtual Machine. 

You can also enter the following command. It should list you all the Virtual
Machines (vms) that VirtualBox recognizes:

bq. VBoxManage list vms

*NOTE*: VirtualBox may complain about missing media at this point. This is most
likely the CD (.iso) file that was used to install the
ubuntu-12.04-server-i386. You can ignore the message. 


*NOTE*: VirtualBox may also complain about not being able to load USB drives.
This is because the version of VirtualBox that comes with Ubuntu does not
support this feature, while the version that was used to build the virtual
image does. In order to fix this, give this command: 

bq. VBoxManage modifyvm ubuntu-12.04-server-i386  --usb off

Create a Virtual Network and give it an IP address to use:

bq. VBoxManage hostonlyif create
bq. VBoxManage hostonlyif ipconfig vboxnet0 --ip 10.13.37.254

Create a virtual network interface on the Ubuntu VM inside the same network:

bq. VBoxManage modifyvm ubuntu-12.04-server-i386 --nic2 hostonly

We now have a VM we can use as a base for deploying many others.

===== Git Clone OldExample/sys =====

*NOTE*: If you do not have access to the github of OldExample/sys, make sure you
get that first. 

In order to use git you will first need to install it:

bq. sudo apt-get install git

Make a clone of the git repository of Oldexample-Sys:

bq. git clone git@github.com:OldExample/sys

You should now have a folder in your homedirectory called 'sys'. Inside that
folder are all the scripts and code related to this project.

===== Checklist =====

If you followed all the steps this far, you should have the following:

* A folder called 'sys' in your homedir containing a clone of the Sys repository.
* A folder called '.VirtualBox' in your homedir.
* The '.Virtualbox' should have a sub-folder called 'ubuntu-12.04-server-i386'.
* In this sub-folder there are two files called 'ubuntu-12.04-server-i386.vdi' and 'ubuntu-12.04-server-i386.vbox'.
* You should have full sudo access.
* /etc/fuse.conf has a line reading 'user_allow_other'.

Why all this effort? Well, from now on, if you want to 

===== puppet-devenv =====

First check if you really do have 'puppet-devenv' in your ~/sys folder. If not,
retrace your steps. 

Open up 'puppet-devenv' and edit the variables to taste. Unless you named
your user 'ubuntu' you will probably need to change the 'INITSCRIPT' variable.

Run puppet-devenv:

bq. ./puppet-devenv

It should give some helpful output.

Create a new VM:

bq. ./puppet-devenv add puppetmaster 10.13.37.10

What happens now is that the image we downloaded earlier is being cloned. The
cloned virtual harddisks are then being altered, so the new VM will have the
correct hostname, IP address and root password. Finally, a script is placed
that will get executed the first time the VM starts up.

After 'puppet-devenv' finishes, you can start your new 'puppetmaster'. 

*NOTE*: I usually start the puppetmaster VM from VirtualBox the first time, so I can see
what is happening. 

After the VM has booted up, it should automatically download and install
the version of puppet we currently use.

TODO: Describe setting up a puppetmaster
TODO: Describe/automate installing DNS on puppetmaster
TODO: Describe installing a puppet-node. 


===== Delete A VM =====

bq. VBoxManage unregistervm pup4 --delete


=== Setup Production Environment ===

Every environment is assumed to have the following nodes:

1. puppetmaster - responsible for distributing configurations to other nodes.
2. loghost - Receives logs from other nodes.
3. monitorhost - Monitors other nodes.
4. mailhost - Handles all e-mail between different nodes and the world.

Each node is assumed to run Ubuntu 12.04 LTS, either AMD64 or i386
architecture.

=== Profiles ===

A profile is a collection of settings and configurations resulting in a node
that provides a certain service within a specific environment. 

For example, we have the profile +mailhost+, which provides mailservices for
the rest of the network. 

What follows is a breakdown of all profiles needed to provide one production
environment.

==== profile: manage ====

This profile creates and manages the configuration management masterserver.
From now on we will refer to this host as the 'puppetmaster', as it manages all
nodes ('puppets') in the production environment.

This profile is also responsible for being the CA (Certificate Authority) to
all other nodes in the environment. It handles the creation, signing,
distributing and revocation of all SSL certificates used for communication
between services.

==== profile: mailhost ====

Responsible for handling all email traffic from hosts to the internet.

The implementation consists of a Postfix installation configured to only accept
emails over an TLS encrypted connection. Using a whitelist of fingerprints,
Postfix only allows connections from validated hosts. All other connections are
dropped. 

It is also configured to accept and store all emails sent to root@ for all
machines in the environment.

The configurations, including the certificates, are placed and maintained by
Puppet and originate from the puppetmaster.

==== profile: loghost ====

Responsible for accepting and handling all syslog logging messages from all
hosts in the managed environment.



The configurations, including the certificates, are placed and maintained by
Puppet and originate from the puppetmaster.


==== profile: backuphost ====
==== profile: monitorhost ====


=== Configuration Management ===

In order to ensure all software is installed and maintained consistently and
repeatably we use configuration management.

=== Backups ===

Each production environment should have one backupserver. Each server will make
local backups first. Daily, the Backupserver will fetch the local backups to
itself. The data on the Backupserver should be stored off-site once a week.

It will backup all files in /home/backup01

The backupserver will use rdiff over ssh.

=== What should be backed up ===

All data-generating services should have a ::backup class in its manifest. 

That class should:

* Make sure the correct backupsoftware is installed.
* Ensure the backup software is configured to run every N days
* Ensure the target folder for the backups is the local /var/backups
* Only trigger if 'backup' is set to '1' (default for production machines)
* Ensure that the target folder (/var/backups) is recursively readable by the
  backup user.

==== MySQL Backup Example ====

MySQL is a database and it is generally assumed that it produces (valuable)
data. As such, the mysql manifest should contain a class called
'mysql::backups'. 


bq. class mysql {
bq. ...
bq. 
bq. if $backup == 1  {
bq. include mysql::backup
bq. }
bq.
bq.
bq. class mysql::backup {
bq.   package { "automysqlbackup":
bq.     ensure => latest,
bq.   }
bq.  file { "/var/backups/automysqlbackup":
bq.    ensure => directory,
bq.  }
  file { "/etc/default//automysqlbackup":
    require => [
                File["/var/backups/automysqlbackup"], 
                Package["automysqlbackup"],
               ],
    ensure  => file,
    content => template("mysql/automysqlbackup.erb"),
  }
}

In the systems.yml file, the default value for backup is '1' for all production
machines. For all non-production machines it is '0' (=no backup).

==== Backuphost ====

Backuphost will gather all the local backups from all the clients that have
'backup' variable set to '1'. 

This is done using ssh-keys. 

===== New SSH Key =====

For security reasons, the ssh private key is not managed by puppet. The public
key is. Should you need a new key, simply log into the backuphost, generate a
new keypair. Place the public key in puppet
(/etc/sys/puppet/modules/common/users/files/backup01.authorized_keys). 

NOTE: Do NOT just copy the pubkey file over to backup01.authorized_keys! Open
the backup01.authorized_keys file and edit it, as it holds more information
than simply that public key!

==== Backups Backlog ====

What has not yet been taken into account:

* How to queue all backups.
* Retention (how long to store data on the backup server)
* Security - how to ensure data is not leaked by using encryption

=== Our custom external node classifier ===

modules/common/puppet/manifests/init.pp writes the puppet configuration using
templates/puppet.conf.erb. This file in turn defines

bq.    external_nodes = /etc/sys/puppet-node.rb

for the management profile. This ruby script is our custom external node
classifier (see http://docs.puppetlabs.com/guides/external_nodes.html ). It
reads and merges the YAML files inside /etc/sys/puppet/.

First, we load systems.yml and determine a few key things:
- the environment the system belongs to
- the profile to apply to the system

It is important that this happens first: it means these values cannot be
overridden from the other configuration files, and that by just reading
systems.yml we can figure these out.

The order of configuration merging is then, from most default to most specific:
- config.yml       (global defaults)
- environments.yml (picking out the specific environment)
- apps.yml         (picking out the specific profile)
- systems.yml       (after picking out the specific system)

From this merged configuration we extract the 'classes' key, which is the
list of classes to apply to the system. To this list we add
- the classes listed in profiles.yml for that profile.
- the classes listed in profiles.yml for the special 'default' profile

(Note that these classes can actually be parameterized classes (see
http://docs.puppetlabs.com/guides/parameterized_classes.html ). This is mostly
a remnant from an older version of this configuration setup where it was hard
to factor in profile-specific configuration. The preferred mechanism to use is
actually to make the puppet modules look at the $profile variable and customize
their behavior based on that.)

Finally, we dump the merged configuration and the list of classes to
stdout (this is what puppet external node classifiers do).

This specific way of organizing the configuration may sound or look a
little bit crazy at first, but actually working with the configuration should
show that this organization allows for just the right kind of
Don't-Repeat-Yourself.








































Local Puppet Docs
=================

These docs are parsable by asciidoc to output nice pages. And are also readable
from the CLI so that you can use it in case of trouble.


Setting Up A New Environment
============================

PuppetMaster
------------

BUG:
Add a dummy host to the PKI.
Run puppet so it generates certificate.
Puppet will complain, but will generate those certs.
Add the host to the revoked: array so the certs get revoked.
Run puppet again on the puppetmaster.
Now puppet should no longer complain.


Files Of Import


Base Services
=============

PKI
---

The PKI is completely managed by manipulating the YAML configuration.
There should be no need to alter any other files, including the pki manifests.



Firewall
--------


Mail
----

All email is forwarded to an internal smarthost. As such, we
make the distinction of a 'postfix' and a 'postfix-client' server in our code.

Smarthost is configured with the following characteristics in mind: 

* Only use TLS
* Only accept anything from hosts with a certificate we trust. 

Postfix is used to provide email. 


SNMP
----

* Firewall blocks all access to port 161 accept for the monitorhost. 
* SNMP listens to all interfaces on 161. 
* Only allows a user with over an encrypted 

Monitoring
---------

Nagios. 

Used References
^^^^^^^^^^^^^^^

Basic config:

* http://blog.gurski.org/index.php/2010/01/28/automatic-monitoring-with-puppet-and-nagios/


Split config over multiple files:
* http://pieter.barrezeele.be/2009/05/11/puppet-and-nagios/
* http://www.linuxjournal.com/content/puppet-and-nagios-roadmap-advanced-configuration



Adding New Servers
==================

A new server will always need to have the following: 

- a loghost to log to
- a smarthost to send email to/through
- a puppetmaster to retrieve it's puppet manifests from 
- part of the PKI, meaning have the CA cert, it's own key and public cert
  signed by the CA.

So adding a new server getting pretty hefty. You will need to edit systems.yml,
and possibly other config. After which you will need to commit and push your
changes. 

The puppetmaster will then need to create the SSL certificates. The loghost
will have to run puppet in order to know that it should receive logs from the
new server. The mailserver dito for mail. The monitoring server will need to
know about this server, etc...etc...



Backups
=======

authorized_keys has ip address hardcoded.



DUMP:
=====
* Puppet is awesome as it:
 * Can log to syslog, so every change is logged
 * Keeps older versions of files, so rollback and verification of change is
   possible.
 * Uses plain textfiles that are provided by a Source Control Management system
   (GIT). This ensures accountability of every change.
 * Cross-platform, available for many different versions of *NIX.
 * Defacto standard for current operational setups.


Options considered: 
OpenNMS + Puppet, but they use the database prefereably, or possibly an API
that let's you query puppet facts gathered by the puppetmaster. Nevertheless,
these are still puppet facts.


Nagios + Puppet Standard, but they use a database filled with facts that are
easily manipulated resulting in manipulation of the puppetmaster and 
monitorhost.

No one seems to be working from the principle that the puppetmaster knows what
is best for the puppets. All prefab solutions I came across at some point
relied on data from puppets. 

TODO: 
=====
* Omschrijf development -> production cycle. (Edit file, save file, push file
  to devenv, test file, test on test node, commit file with ticketnr, pull on
  manage01, puppet test role)
