class apt::repo::packages {
  package { ["gnupg", "dpkg-sig", "rng-tools", "reprepro"]:
    ensure => "${package_ensure}",
    require => [
      User["reprepro"],
      Group["reprepro"],
    ],
  }
}

class apt::repo::services {
  service { "rng-tools":
    ensure  => running,
    enable  => true,
    require => Class["apt::repo::packages"],
  }
}

class apt::repo::setup {
  $key_name     = "${server_admin_email}"
  $codename     = "precise"
  $publish_name = $apt[publish_name]

  $publish_dir    = $apt[publish_dir]
  $publish_key    = "${publish_dir}/${key_name}.gpg"
  $publish_ascii  = "${publish_dir}/${key_name}.gpg.key"
  $publish_cfg    = "${publish_dir}/${publish_name}.list"
  $publish_secure = "${publish_dir}/00securerepo"

  $basedir      = "/home/reprepro"
  $reposdir     = "/home/reprepro/repos"
  $repodir      = "${reposdir}/${publish_name}"
  $confdir      = "${repodir}/conf"
  $incomingdir  = "${repodir}/incoming"
  $promodir     = "${repodir}/promote"

  $repoheader   = "${repodir}/.HEADER.html"

  $appdir       = "${repodir}/app"
  $upload_php   = "${appdir}/upload.php"
  $promote_php  = "${appdir}/promote.php"

  $includedebs  = "${basedir}/includedebs.sh"
  $promotedeb   = "${basedir}/promotedeb.sh"
  $promotedebs  = "${basedir}/promotedebs.sh"

  $distroconf   = "${confdir}/distributions"
  $repreproconf = "${confdir}/options"
  
  $gnupg_dir    = "${basedir}/.gnupg"
  $genkey_conf  = "${gnupg_dir}/gen-key.cfg"
  $genkey_tgt   = "${gnupg_dir}/${key_name}.gpg"
  $genkey_ascii = "${repodir}/${key_name}.gpg.key"
  
  # make reprepro part of apache's group so it can rm uploaded files
  exec { "reprepro-is-part-of-www-data":
    user          => root,
    command       => "/usr/sbin/usermod -a -G www-data reprepro",
    require       => [
      Package["reprepro"],
    ],
    onlyif        => "sh -c '! /usr/bin/groups reprepro | grep www-data'",
  }

  # rng-tools is being configured to use the pseudorandom number
  #   generator so that gpg does not run out of entropy
  file { "/etc/default/rng-tools":
      source  => "puppet://puppet/modules/apt/rng-tools.cfg",
      owner   => "root",
      group   => "root",
      mode    => 644,
      notify  => Service["rng-tools"],
  }

  # file { "${basedir}":
  #   ensure  => directory,
  #   owner   => "reprepro", 
  #   group   => "reprepro",
  #   mode    => 0755,
  #   require => User["reprepro"],
  # }
  
  # catch emails from failed cron job
  file { "${basedir}/.forward":
    ensure  => file,
    owner   => "reprepro", 
    group   => "reprepro",
    mode    => 0644,
    content => "${server_admin_email}",
    require => [
      File["${basedir}"],
    ],
  }
  
  # set up directories
  
  file { "${reposdir}":
    ensure  => directory,
    owner   => "reprepro", 
    group   => "reprepro",
    mode    => 0755,
    require => File["${basedir}"],
  }
  
  file { "${repodir}":
    ensure  => directory,
    owner   => "reprepro", 
    group   => "reprepro",
    mode    => 0755,
    require => File["${reposdir}"],
  }
  
  file { "${confdir}":
    ensure  => directory,
    owner   => "reprepro", 
    group   => "reprepro",
    mode    => 0755,
    require => File["${repodir}"],
  }
  
  file { "${incomingdir}":
    ensure  => directory,
    owner   => "reprepro", 
    group   => "www-data",
    mode    => 01775,
    require => [
      File["${repodir}"],
      Package["apache2"],
    ],
  }
  
  file { "${promodir}":
    ensure  => directory,
    owner   => "reprepro", 
    group   => "www-data",
    mode    => 01775,
    require => [
      File["${repodir}"],
      Package["apache2"],
    ],
  }
  
  # friendly website header
  file { "${repoheader}":
    ensure  => file,
    owner   => "reprepro", 
    group   => "reprepro",
    mode    => 0644,
    content => template("apt/repo.HEADER.html.erb"),
    require => [
      File["${repodir}"],
    ],
  }
  
  # location for php scripts
  file { "${appdir}":
    ensure  => directory,
    owner   => "reprepro", 
    group   => "www-data",
    mode    => 0755,
    require => [
      File["${repodir}"],
      Package["apache2"],
    ],
  }
  
  # php script to upload packages to incoming/
  file { "${upload_php}":
    ensure  => file,
    owner   => "reprepro", 
    group   => "reprepro",
    mode    => 0644,
    content => template("apt/upload.php.erb"),
    require => [
      File["${appdir}"],
    ],
  }
  
  # php script to create promote/ requests
  file { "${promote_php}":
    ensure  => file,
    owner   => "reprepro", 
    group   => "reprepro",
    mode    => 0644,
    content => template("apt/promote.php.erb"),
    require => [
      File["${appdir}"],
    ],
  }
  
  # shell script run from cron to process incoming/ packages
  file { "${includedebs}":
    ensure  => file,
    owner   => "reprepro", 
    group   => "reprepro",
    mode    => 0755,
    content => template("apt/includedebs.sh.erb"),
    require => [
      File["${basedir}"],
      Class["apt::repo::packages"],
    ],
  }
  
  # cron job to process incoming/ packages
  cron { "update-apt-incoming ${publish_name}":
    command => "${includedebs}",
    user    => reprepro,
    minute  => "*/5",
  }

  # shell script to promote package from devel to main from CLI
  file { "${promotedeb}":
    ensure  => file,
    owner   => "reprepro", 
    group   => "reprepro",
    mode    => 0755,
    content => template("apt/promotedeb.sh.erb"),
    require => [
      File["${basedir}"],
      Class["apt::repo::packages"],
    ],
  }
  
  # shell script run from cron to process promote/ requests
  file { "${promotedebs}":
    ensure  => file,
    owner   => "reprepro", 
    group   => "reprepro",
    mode    => 0755,
    content => template("apt/promotedebs.sh.erb"),
    require => [
      File["${basedir}"],
      Class["apt::repo::packages"],
    ],
  }
  
  # cron job to process promote/ requests
  cron { "update-apt-promote ${publish_name}":
    command => "${promotedebs}",
    user    => reprepro,
    minute  => "*/5",
  }

  # configuration for reprepro
  file { "${distroconf}":
    ensure  => file,
    owner   => "reprepro", 
    group   => "reprepro",
    mode    => 0644,
    content => template("apt/distributions.erb"),
    require => File["${confdir}"],
    notify  => Exec["reprepro-export"],
  }
  
  file { "${repreproconf}":
    ensure  => file,
    owner   => "reprepro", 
    group   => "reprepro",
    mode    => 0644,
    content => template("apt/options.erb"),
    require => File["${confdir}"],
    notify  => Exec["reprepro-export"],
  }
  
  # reprepro needs a GNUPG key for signing things
  file { "${gnupg_dir}":
    ensure  => directory,
    owner   => "reprepro", 
    group   => "reprepro",
    mode    => 0700,
    require => File["${basedir}"],
  }
  
  file { "${genkey_conf}":
    ensure  => file,
    owner   => "reprepro", 
    group   => "reprepro",
    mode    => 0700,
    content => template("apt/gen-key.cfg.erb"),
    require => File["${gnupg_dir}"],
  }
  
  exec { "reprepro-gpg-gen-key":
    command => "gpg --homedir ${gnupg_dir} --gen-key --batch ${genkey_conf}",
    cwd     => "${basedir}",
    group   => "reprepro",
    user    => "reprepro",
    unless  => "gpg --list-key ${key_name}",
    require => [
      File["${genkey_conf}"],
      Class["apt::repo::packages"],
      Class["apt::repo::services"],
    ],
    notify  => Exec["reprepro-export"],
  }
  
  exec { "reprepro-gpg-export-key":
    command => "gpg --homedir ${gnupg_dir} --export --batch ${key_name} > ${genkey_tgt}",
    cwd     => "${basedir}",
    group   => "reprepro",
    user    => "reprepro",
    creates => "${genkey_tgt}",
    require => [
      Exec["reprepro-gpg-gen-key"],
    ],
  }
  
  exec { "reprepro-gpg-export-ascii":
    command => "gpg --homedir ${gnupg_dir} --export --armor --batch ${key_name} > ${genkey_ascii}",
    cwd     => "${basedir}",
    group   => "reprepro",
    user    => "reprepro",
    creates => "${genkey_ascii}",
    require => [
      Exec["reprepro-gpg-gen-key"],
    ],
  }
  
  # publish things into apt/files for pickup by client hosts
  exec { "reprepro-gpg-publish-key":
    command => "cp ${genkey_tgt} ${publish_key}",
    cwd     => "${basedir}",
    creates => "${publish_key}",
    require => Exec["reprepro-gpg-export-key"],
  }
  
  exec { "reprepro-gpg-publish-ascii":
    command => "cp ${genkey_ascii} ${publish_ascii}",
    cwd     => "${basedir}",
    creates => "${publish_ascii}",
    require => Exec["reprepro-gpg-export-ascii"],
    notify  => File["/etc/apt/${key_name}.gpg.key"],
  }
  
  file { "${publish_cfg}":
    ensure  => file,
    owner   => "puppet", 
    group   => "puppet",
    mode    => 0644,
    content => template("apt/sources.list.erb"),
    notify  => File["/etc/apt/sources.list.d/${publish_name}.list"],
  }
  
  file { "${publish_secure}":
    ensure  => file,
    owner   => "puppet", 
    group   => "puppet",
    mode    => 0644,
    content => template("apt/00securerepo.erb"),
    notify  => File["/etc/apt/apt.conf.d/00securerepo"],
  }
  
  exec { "reprepro-export":
    command     => "reprepro --gnupghome=${gnupg_dir} export",
    cwd         => "${repodir}",
    group       => "reprepro",
    user        => "reprepro",
    refreshonly => true,
  }
}

class apt::repo {
  # class for server(s) hosting apt repositor(y|ies)
  include apt::repo::packages, apt::repo::services, apt::repo::setup
}

class apt::host::packages {
  package { "python-software-properties":
    ensure      => "${package_ensure}",
  }
}

class apt::rackspace::backup {
  file { "/etc/apt/agentrepo.gpg.key":
    source  => "puppet://puppet/modules/apt/rackspace_backup.key",
    owner   => "root",
    group   => "root",
    mode    => 0644,
    notify  => Exec["apt-key-import-rackspace_backup"],
  }

  file { "/etc/apt/sources.list.d/driveclient.list":
    source  => "puppet://puppet/modules/apt/rackspace_backup.list",
    owner   => "root",
    group   => "root",
    # _should_ be set to 0600 since it contains the http basic password used by apt as plain text
    # however, apt-check does not work if it can't read this file.
    mode    => 0644,
    notify  => Class["basepackages::aptupdate"],
  }
  
  exec { "apt-key-import-rackspace_backup":
    command     => "apt-key add /etc/apt/agentrepo.gpg.key",
    group       => "root",
    user        => "root",
    refreshonly => true,
    notify  => Class["basepackages::aptupdate"],
  }
}

class apt::tomcat::backports {
  # dirk has upgrade to 7.0.39. The new package breaks our setup for some unknown reason.
  #   so, I've pushed the old packages (7.0.34) into our own apt repo. Use those.
  # To fix a machine:
  #   /etc/init.d/apache2 stop
  #   /etc/init.d/tomcat7 stop
  #   apt-get remove tomcat7 tomcat7-common libtomcat7-java libservlet3.0-java
  #   dpkg --purge tomcat7 tomcat7-common libtomcat7-java libservlet3.0-java
  #   rm /etc/apt/sources.list.d/dirk-computer42-c42-backport-precise.list
  #   apt-get update
  #   apt-get install tomcat7=7.0.34-0ubuntu1~precise1~ppa1 \
  #     tomcat7-common=7.0.34-0ubuntu1~precise1~ppa1 \
  #     libtomcat7-java=7.0.34-0ubuntu1~precise1~ppa1 \
  #     libservlet3.0-java=7.0.34-0ubuntu1~precise1~ppa1
  #   /etc/init.d/tomcat7 stop
  #   puppet agent -t
  #   /etc/init.d/tomcat7 restart
  #   /etc/init.d/apache2 restart
  #
  # exec { "add-tomcat-backports":
  #   command     => "add-apt-repository -y ppa:dirk-computer42/c42-backport",
  #   group       => "root",
  #   user        => "root",
  #   require     => Package["python-software-properties"],
  #   creates     => "/etc/apt/sources.list.d/dirk-computer42-c42-backport-precise.list",
  # }

  file { "/etc/apt/sources.list.d/dirk-computer42-c42-backport-precise.list":
    ensure  => "absent",
  }
  
  exec { "tomcat-backports-update":
    command     => "apt-get update",
    group       => "root",
    user        => "root",
    #subscribe   => Exec["add-tomcat-backports"],
    subscribe   => File["/etc/apt/sources.list.d/dirk-computer42-c42-backport-precise.list"],
    refreshonly => true
  }
}

class apt::postgres::backports {
  # INFRA-199: note at time of writing this will upgrade postgres from 9.1 to 9.2
  # but this does not upgrade the cluster, so still need to use
  #   http://manpages.ubuntu.com/manpages/karmic/man8/pg_upgradecluster.8.html
  # like so:
  #   sudo -u postgres pg_dropcluster --stop 9.2 main
  #   sudo -u postgres rsync -a /var/lib/postgresql/9.1 /var/lib/postgresql/9.1.backup
  #   screen sudo -u postgres pg_upgradecluster 9.1 main /var/lib/postgresql/9.2
  # check results:
  #   sudo -u postgres psql
  # and if all is well, clean up:
  #   sudo -u postgres pg_dropcluster 9.1 main 
  
  exec { "add-postgres-backports-key":
    command     => "curl http://apt.postgresql.org/pub/repos/apt/ACCC4CF8.asc | apt-key add -",
    group       => "root",
    user        => "root",
    require     => Package["python-software-properties"],
    onlyif      => "sh -c '! apt-key list | grep ACCC4CF8'",
  }
  
  exec { "add-postgres-backports":
    command     => "add-apt-repository -y 'deb http://apt.postgresql.org/pub/repos/apt/ precise-pgdg main'",
    group       => "root",
    user        => "root",
    require     => Exec["add-postgres-backports-key"],
    onlyif      => "sh -c '! cat /etc/apt/sources.list | grep apt.postgresql.org'",
  }
  
  exec { "postgres-backports-update":
    command     => "apt-get update",
    group       => "root",
    user        => "root",
    subscribe   => Exec["add-postgres-backports"],
    refreshonly => true
  }
  
  package { "pgdg-keyring":
    ensure      => "${package_ensure}",
    require     => Exec["postgres-backports-update"],
  }
  
  file { "/etc/apt/preferences.d/pgdg.pref":
    source  => "puppet://puppet/modules/apt/pgdg.pref",
    owner   => "root",
    group   => "root",
    mode    => 0644,
    require => Exec["add-postgres-backports"]
  }
}



class apt::host::publish {
  $key_name     = "${server_admin_email}"
  $publish_name = $apt[publish_name]

  # not sure why, but this causes issues. It seems better to use add-key explicitly.
  # file { "/etc/apt/trusted.gpg.d/${key_name}.gpg":
  #   source  => "puppet://puppet/modules/apt/${key_name}.gpg",
  #   owner   => "root",
  #   group   => "root",
  #   mode    => 0644,
  # }

  file { "/etc/apt/${key_name}.gpg.key":
    source  => "puppet://puppet/modules/apt/${key_name}.gpg.key",
    owner   => "root",
    group   => "root",
    mode    => 0644,
    notify  => Exec["apt-key-import-${key_name}"],
  }

  file { "/etc/apt/sources.list.d/${publish_name}.list":
    source  => "puppet://puppet/modules/apt/${publish_name}.list",
    owner   => "root",
    group   => "root",
    # _should_ be set to 0600 since it contains the http basic password used by apt as plain text
    # however, apt-check does not work if it can't read this file.
    mode    => 0644,
    notify  => Class["basepackages::aptupdate"],
  }

  file { "/etc/apt/apt.conf.d/00securerepo":
    source  => "puppet://puppet/modules/apt/00securerepo",
    owner   => "root", 
    group   => "root",
    mode    => 0644,
    notify  => Class["basepackages::aptupdate"],
  }
  
  exec { "apt-key-import-${key_name}":
    command     => "apt-key add /etc/apt/${key_name}.gpg.key",
    group       => "root",
    user        => "root",
    refreshonly => true,
    notify      => Class["basepackages::aptupdate"],
  }
}

class apt::host {
  # class for hosts to use our apt repositor(y|ies)
  include apt::host::packages
  include apt::host::publish
  include apt::rackspace::backup
  include apt::tomcat::backports
  include apt::postgres::backports
}
