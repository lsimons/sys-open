class puppetmaster::packages {
  $puppet_version = $puppet[version]

  package { ["puppetmaster"]:
    ensure  => "${puppet_version}",
    require => Class["puppet::packages"],
    notify  => Service["puppetmaster"],
  }
}

class puppetmaster::config {
  # todo
  firewall::allow { "allow-puppet-from-all":
    port    => 8140,
    ip      => "any",
    proto   => "tcp",
  }
  
  file { "/etc/puppet/manifests":
    ensure  => "directory",
    owner   => "root",
    group   => "root",
    mode    => 644,
    require => Class["puppet"]
  }

  file { "/etc/puppet/manifests/site.pp":
    ensure => "/etc/sys/puppet/site.pp",
    require => File["/etc/puppet/manifests"]
  }
}

class puppetmaster::services {
  service { "puppetmaster":
    enable  => false, # disabled because we are using passenger, see below
    ensure  => stopped,
    # disable after apache has been configured to be puppetmaster,
    #   but before it is restarted to be the puppetmaster
    require => [
      Class["puppetmaster::packages", "puppetmaster::config"],
      File["/etc/apache2/sites-enabled/puppetmaster.conf"]
    ],
    notify => Service["apache2"]
  }

  # exec { "puppetmaster-restarted":
  #   command     => "/bin/bash -c \"echo -n puppet master restarting... && sleep 5 && echo\"",
  #   refreshonly => true,
  #   subscribe   => Service["puppetmaster"],
  #   logoutput   => true,
  # }

  exec { "puppetmaster-restarted":
   command     => "/bin/bash -c \"echo -n puppet master restarting... && sleep 5 && echo\"",
   refreshonly => true,
   subscribe   => Service["apache2"],
   logoutput   => true,
  }
}

class puppetmaster::cron {
  cron { "clean-puppet-reports":
    command => "/usr/bin/find /var/lib/puppet/reports/ -mtime +7 -name '*.yaml' | /usr/bin/xargs /bin/rm",
    user    => puppet,
    hour    => 03,
    minute  => 00,
  }

  cron { "puppetmaster-restart":
    command => "/etc/init.d/puppetmaster restart >/dev/null",
    user    => root,
    hour    => 02,
    minute  => 00,
    ensure  => "absent", # disabled because we are now using passenger
  }
}

class puppetmaster::passenger {
  # note http://docs.puppetlabs.com/guides/platforms.html#ruby-versions
  #   we normally install ruby 1.9.x (systemrvm package) and associated
  #   passenger, but, we need ruby 1.8 and its passenger for puppet 2.x
  # so, we go with the ubuntu-default passenger and codify
  #   http://docs.puppetlabs.com/guides/passenger.html
  # this means systemrvm cannot be installed on the puppetmaster...
  
  $passenger_version = "${puppet[passenger_version]}"

  $maxpoolsize = "${puppet[passenger_maxpoolsize]}"
  $poolidletime = "${puppet[passenger_poolidletime]}"
  $mininstances = "${puppet[passenger_mininstances]}"
  $maxinstancesperapp = "${puppet[passenger_maxinstancesperapp]}"
  $spawnmethod = "${puppet[passenger_spawnmethod]}"

  $ruby_cmd = "/usr/bin/ruby1.8"
  $gem_path = "/var/lib/gems/1.8/gems"
  $passenger_gem_path = "${gem_path}/passenger-$passenger_version"
  $rvm_passenger_gem_path = "${passenger_gem_path}"
  $passenger_apache_module = "${passenger_gem_path}/ext/apache2/mod_passenger.so"
  
  package { ["ruby1.8-dev", "rubygems",
             "apache2-prefork-dev", "libapr1-dev", "libaprutil1-dev", "libcurl4-openssl-dev"]:
    ensure => "${package_ensure}",
    require => Class["puppetmaster::packages", "apache"]
  }

  exec { "puppetmaster-install-rack":
    command => "gem install rack",
    unless => "gem list -l | grep rack",
    timeout => 600,
    require => Package["ruby1.8-dev", "rubygems"],
  }
  
  exec { "puppetmaster-install-passenger":
    command => "gem install passenger --version $passenger_version",
    unless => "gem list -l | grep passenger | grep $passenger_version",
    timeout => 600,
    require => [
      Package["ruby1.8-dev", "rubygems"],
      Exec["puppetmaster-install-rack"]
    ]
  }
  
  exec { "puppetmaster-install-passenger-apache2-module":
    command => "passenger-install-apache2-module -a",
    creates => "$passenger_apache_module",
    timeout => 600,
    require => [
      Exec["puppetmaster-install-passenger"],
      Package["apache2-prefork-dev", "libapr1-dev", "libaprutil1-dev", "libcurl4-openssl-dev"]
    ]
  }

  file {
    '/etc/apache2/mods-available/passenger.load':
      ensure  => file,
      content => "LoadModule passenger_module $passenger_apache_module",
      require => Exec['puppetmaster-install-passenger-apache2-module'],
      notify => Service["apache2"];

    '/etc/apache2/mods-enabled/passenger.load':
      ensure  => 'link',
      target  => '../mods-available/passenger.load',
      require => File['/etc/apache2/mods-available/passenger.load'],
      notify => Service["apache2"];

    '/etc/apache2/mods-available/passenger.conf':
      ensure  => file,
      content => template('systemrvm/passenger-apache.conf.erb'),
      require => Exec['puppetmaster-install-passenger-apache2-module'],
      notify => Service["apache2"];

    '/etc/apache2/mods-enabled/passenger.conf':
      ensure  => 'link',
      target  => '../mods-available/passenger.conf',
      require => File['/etc/apache2/mods-available/passenger.conf'],
      notify => Service["apache2"];
    
    '/usr/share/puppet/rack':
      ensure  => 'directory',
      require => Package["puppet"];
      
    '/usr/share/puppet/rack/puppetmasterd':
      ensure  => 'directory',
      require => File['/usr/share/puppet/rack'];

    '/usr/share/puppet/rack/puppetmasterd/public':
      ensure  => 'directory',
      require => File['/usr/share/puppet/rack/puppetmasterd'];

    '/usr/share/puppet/rack/puppetmasterd/tmp':
      ensure  => 'directory',
      require => File['/usr/share/puppet/rack/puppetmasterd'];

    '/usr/share/puppet/rack/puppetmasterd/config.ru':
      ensure  => '/usr/share/puppet/ext/rack/files/config.ru',
      owner   => puppet,
      require => [
        File['/usr/share/puppet/rack/puppetmasterd'],
        Package["puppetmaster"]
      ];

    '/etc/apache2/sites-available/puppetmaster.conf':
      ensure  => file,
      content => template('puppetmaster/puppetmaster_vhost.conf.erb'),
      require => [
        File['/etc/apache2/mods-enabled/passenger.conf'],
        File['/usr/share/puppet/rack/puppetmasterd/config.ru'],
      ],
      notify => Service["apache2"];

    '/etc/apache2/sites-enabled/puppetmaster.conf':
      ensure  => 'link',
      target  => '../sites-available/puppetmaster.conf',
      require => [
        File['/etc/apache2/mods-enabled/passenger.conf'],
        File['/usr/share/puppet/rack/puppetmasterd/config.ru'],
      ],
      notify => Service["apache2"];

  }

}

class puppetmaster::repo {
  # auto update from github using cron
  file { "/etc/cron.d/update_puppetmaster":
    content => "#PUPPET\n*/5 * * * * root cd /etc/sys && git pull > /dev/null 2>&1\n";
  }
}

class puppetmaster {
  include puppetmaster::packages, puppetmaster::config, puppetmaster::services, puppetmaster::cron, puppetmaster::repo
  include puppetmaster::passenger
}
