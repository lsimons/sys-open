

class basepackages::aptupdate {

  # Every package-installing class should require this class.
  # Else you will get old packages, or errors.
  exec { "apt-get update":
    path => "/usr/bin",
    returns => [0, 1, 100], # do not fail puppet run if apt-get update fails, since otherwise we can't fix the apt config
    # subscribe => File["/etc/apt/sources.list"],
  }
}

class basepackages::autoaptupdate {
  # auto update for apt
  file { "/etc/cron.d/autoaptupdate":
    content => "#PUPPET\n @hourly root apt-get update > /dev/null 2>&1\n";
  }
}


class basepackages::config {
  # Default sources.list.
  # file { "/etc/apt/sources.list":
  #   ensure  => file,
  #   content => template("basepackages/sources.list.erb"),
  # }
  
  # Disable "Graph this data and manage this system at https://landscape.canonical.com/"
  #    http://ubuntuforums.org/archive/index.php/t-1045189.html
  exec { "mkdir -p /usr/share/pyshared/landscape/sysinfo": 
    # Crazy puppet still cannot and will not create subfolders if parentfolder
    # does not exist.
    creates => "/usr/share/pyshared/landscape/sysinfo",
  }
  file { "/usr/share/pyshared/landscape/sysinfo":
    ensure  => directory,
    owner   => "root", 
    group   => "root",
    mode    => 0755,
    require => [
      Exec["mkdir -p /usr/share/pyshared/landscape/sysinfo"],
    ],
  }
  file { "/usr/share/pyshared/landscape/sysinfo/landscapelink.py":
    ensure => file,
    source  => "puppet://puppet/modules/basepackages/landscapelink.py",
    require => File["/usr/share/pyshared/landscape/sysinfo"],
    # does not work for file onlyif  => "test -e /usr/share/pyshared/landscape/sysinfo/landscapelink.py",
  }
}

class basepackages {
  include basepackages::config
  include basepackages::aptupdate
  include basepackages::autoaptupdate
  # install some utility packages
  if ! defined(Package['bc'])             { package { 'bc':             ensure => "${package_ensure}" } }
  if ! defined(Package['curl'])           { package { 'curl':           ensure => "${package_ensure}" } }
  if ! defined(Package['libcurl3'])       { package { 'libcurl3':       ensure => "${package_ensure}" } }
  if ! defined(Package['libcurl3-gnutls']){ package { 'libcurl3-gnutls':ensure => "${package_ensure}" } }
  if ! defined(Package['rdiff-backup'])   { package { 'rdiff-backup':   ensure => "${package_ensure}" } }
  if ! defined(Package['vim'])            { package { 'vim':            ensure => "${package_ensure}" } }
  if ! defined(Package['wget'])           { package { 'wget':           ensure => "${package_ensure}" } }

  # I think Maarten was a fan of screen, but I think of it as a bit of a security risk
  if ! defined(Package['screen'])         { package { 'screen':         ensure => "absent" } }
  
  # set ensure => ... for the 'core' packages that are always installed by ubuntu
  #   and that are high priority security updates. That way, if ensure => latest,
  #   we will auto-update a lot of security patches for that enviornment.
  if ! defined(Package['bash'])           { package { 'bash':           ensure => "${package_ensure}" } }
  if ! defined(Package['cron'])           { package { 'cron':           ensure => "${package_ensure}" } }
  if ! defined(Package['iptables'])       { package { 'iptables':       ensure => "${package_ensure}" } }
  if ! defined(Package['libc-bin'])       { package { 'libc-bin':       ensure => "${package_ensure}" } }
  if ! defined(Package['libc6'])          { package { 'libc6':          ensure => "${package_ensure}" } }
  if ! defined(Package['libpam-modules']) { package { 'libpam-modules': ensure => "${package_ensure}" } }
  if ! defined(Package['libpam-modules-bin']) { package { 'libpam-modules-bin': ensure => "${package_ensure}" } }
  if ! defined(Package['libpam-runtime']) { package { 'libpam-runtime': ensure => "${package_ensure}" } }
  if ! defined(Package['libpam0g'])       { package { 'libpam0g':       ensure => "${package_ensure}" } }
  if ! defined(Package['libselinux1'])    { package { 'libselinux1':    ensure => "${package_ensure}" } }
  if ! defined(Package['linux-headers-virtual']) { package { 'linux-headers-virtual': ensure => "${package_ensure}" } }
  if ! defined(Package['linux-image-virtual']) { package { 'linux-image-virtual':     ensure => "${package_ensure}" } }
  if ! defined(Package['linux-virtual'])  { package { 'linux-virtual':  ensure => "${package_ensure}" } }
  # defined in 'sshd' module
  #if ! defined(Package['openssh-client']) { package { 'openssh-client': ensure => "${package_ensure}" } }
  #if ! defined(Package['openssh-server']) { package { 'openssh-server': ensure => "${package_ensure}" } }
  if ! defined(Package['passwd'])         { package { 'passwd':         ensure => "${package_ensure}" } }
  # sudo is defined in sudo/manifests/init.pp which is part of the default profile
  #if ! defined(Package['sudo'])           { package { 'sudo':           ensure => "${package_ensure}" } }
  if ! defined(Package['ubuntu-minimal']) { package { 'ubuntu-minimal': ensure => "${package_ensure}" } }
  if ! defined(Package['ubuntu-standard']){ package { 'ubuntu-standard':ensure => "${package_ensure}" } }
  if ! defined(Package['upstart'])        { package { 'upstart':        ensure => "${package_ensure}" } }
  
  file { "/var/log/puppet_lastran.log":
    require => Class["snmp::packages"], #<-- ensuring snmp user exists.
    owner   => snmp, 
    group   => snmp, 
    content => template("basepackages/puppet_lastran.log.erb"),
  }
}
