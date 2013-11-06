This repository is an anonymzed/neutered version of an actual 'sys' github
repository used by MEDvision360 for managing infrastructure and operations
of its environment.

It is _not_ suitable in its current form for creating a platform from scratch:
manifests and config files will need some editing to be useful outside of
the MEDvision360 context. Rather, the intent is that this repository can be a
useful practical example/case study for applying puppet to produce a
more-secure-than-usual high-level-of-automation setup.

Two disclaimers apply to that word "secure":
1) the practical/effective security of a hosting infrastructure is at least
as much about processes and dilligent maintenance as it is about
technicalities, so merely applying these puppet manifests and patterns by
itself will also not provide you with sufficient security;

2) in order to protect our actual infrastructure, some details of how we've
set up our core linux user management, firewall, and SSL system have been
altered slightly. Though there should be nothing in this puppet configuration
that makes a vanilla ubuntu server installation less secure than it is by
default (especially not when using the live/production environment examples),
there is of course no guarantee that the end result is secure enough for
any purpose.

See puppet/README.txt for some more details of how things are set up.

Licensing info
==============
The bulk of the contents of this repository are licensed under the Apache
License, v2.0, see LICENSE.txt and NOTICE.txt.

puppet/modles/common/firewall is licensed under
puppet/modles/common/firewall/LICENSE
(the MIT license).

puppet/modules/common/rvm is licensed under
puppet/modules/common/rvm/LICENSE
(the BSD license).

puppet/modules/common/snmp/files/mibs/{iana,ietf} are not open source and
so are not included in this repository. You should add them yourself.

Executive summary
=================
MEDvision360 have created a secure, repeatable and usage agnostic
framework enabling managable infrastructures for IT Operations able to
facilitate an unbounded number of projects with an unbounded number of (virtual)
machines. 

The framework enables the management of several services that together make up
a complete IT infrastructure that is ready to provide a platform for the
deployment of several applications in a secure and structured manner. It is simple
to expand and fairly easy to maintain. Repetitive steps that normally can
easily take up days to complete are fully automated. Afterthoughts such as
backups or trending are now automatically added to each new machine.

It is infrastructure-in-a-box.

Special care has been taken to provide high security throughout the platform,
standardizing on the use of SSL certificate-authenticated and encrypted
communication for all infrastructure. Applying this approach through the
infrastructure results in an environment suitable for the kinds of applications
that Example focuses on, which can contain sensitive financial and/or
medical information.

At its base the framework has three levels of configuration defaults and/or
settings: 

1. Environments
2. Profiles
3. Host specific

Depending on the 'environment' and the 'profile' that has been assigned to a
host, certain rules apply. 

An example: In our 'production' environment, all hosts are backed up and
monitored by default. Whereas in our 'development' environment, no host is
monitored, nor are any backed up. These values can be overwritten at the 'host
specific' level.

Central to the infrastructure is the configuration management service (puppet).
Puppet provides other services with their configurations. It does so by pushing
the configuration from the configuration management server to all other
servers. It is also self-aware, meaning that it also provides itself with its
own configuration. 

All configurations are plain text files and often contain programming code. As
such, a revision version control system (git) is used to control the changes
made to the configurations. From git the configurations are automatically
placed on the central configuration management server. As such, each alteration
to every configuration is auditable.

The network connection between the configuration management server and its
targets is encrypted using SSL certificates. These certificates are unique to
each node and are only used for the distribution of the configuration files.

The configuration management server also doubles as a Certificate Authority
(CA). For all the targets that the configuration management server services, it
also creates and signs a certificate with which the target can identify itself
(or the services it provides) to other services inside the infrastructure. 
A Certificate Revocation List is generated and made available through Puppet
whenever a certificate is revoked by an Administrator.

Each node has a firewall that is configured through puppet. The firewall
configuration is automatically generated based on the service that is provided.
E.g: A webserver will automatically have port 443 open in order to provide the
service 'https'. 

Each server that is managed by the framework is automatically monitored for
incidents by the monitoring service (Nagios). Monitoring is done using SNMPv3
connections where only the monitorhost is allowed to connect as a client to the
SNMP service on each target. Should a new monitorhost be installed and
configured, this change will automatically be implemented on all SNMP
configurations.

Alongside active monitoring for incidents the monitorhost also keeps
long-term records of perfomance metrics. These can be used for troubleshooting,
capacity planning and christmastree decorations. The network connections for
this service (Munin) are encrypted using the certificates provided by the CA of
the infrastructure.

Many reasons exist for a node to contact an administrator (or another human
being). To facilitate this each infrastructure needs an e-mail host (mailhost).
The mailhost acts as a hub for the entire infrastructure, relaying internal
e-mails to the outside world. Both the e-mail client and the e-mail server are
implemented using Postfix. Connections between the e-mail client and the e-mail
server are encrypted using the certificates provided by the CA of the
infrastructure. 

As a server is used, it generates systemlogs. These include information such as
the stopping and starting of services, the logging in and out of system
administrators and error messages. Systemlogs are kept both locally on a node
and remotely on a loghost (rsyslog). The loghost is implemented using Rsyslog
which uses the PKI to encrypt all network messages that travel over the
network. The configuration of the loghost is automatically generated to only
service active nodes in the network. Logs are, for the moment, kept
indefinitely. 

This entire framework is managed by the editing of simple configuration files.
These files are only editable through the use of the implemented version
control system (Git). Thus every change can be reviewed and rolled back if
there is need. 
