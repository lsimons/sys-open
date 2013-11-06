class apache::packages {
  package { ["apache2", "libapr1", "libaprutil1"]:
    ensure => "${package_ensure}"
  }
}

class apache::config {

  exec { "enable-apache-ssl":
    user        => root,
    command     => "a2enmod ssl",
    notify      => Service["apache2"],
    require     => Class["apache::packages"],
    onlyif      => "sh -c '! file /etc/apache2/mods-enabled/ssl.conf'"
  }
  
  file { "/etc/apache2/mods-available/ssl.conf":
    ensure  => "file",
    owner   => "root",
    group   => "root",
    mode    => 644,
    source  => "puppet://puppet/modules/apache/ssl.conf",
    notify  => Service["apache2"],
    require => [
      Class["apache::packages", "pki::host::publish"],
    ],
  }

  # INFRA-187
  file { "/etc/apache2/conf.d/security":
    ensure  => "file",
    owner   => "root",
    group   => "root",
    mode    => 644,
    source  => "puppet://puppet/modules/apache/security.conf",
    notify  => Service["apache2"],
    require => [
      Class["apache::packages"],
    ],
  }

  file { "/usr/local/bin/apache_accesslog":
    ensure  => "file",
    owner   => "root",
    group   => "root",
    mode    => 755,
    source  => "puppet://puppet/modules/apache/apache_accesslog",
  }

  file { "/usr/local/bin/apache_errorlog":
    ensure  => "file",
    owner   => "root",
    group   => "root",
    mode    => 755,
    source  => "puppet://puppet/modules/apache/apache_errorlog",
  }

  file { "/etc/apache2/conf.d/logging.conf":
    ensure  => "file",
    owner   => root,
    group   => root,
    mode    => 644,
    content => template("apache/logging.conf.erb"),
    require => Class["apache::packages"],
    notify  => Service["apache2"],
  }

  file { "/etc/apache2/conf.d/other-vhosts-access-log":
    ensure  => absent,
  }
  
  exec { "disable-apache-default-site":
    user        => root,
    command     => "a2dissite default",
    notify      => Service["apache2"],
    require     => Class["apache::packages"],
    onlyif      => "file /etc/apache2/sites-enabled/000-default"
  }

  exec { "enable-apache-headers":
    user        => root,
    command     => "a2enmod headers",
    notify      => Service["apache2"],
    require     => Class["apache::packages"],
    onlyif      => "sh -c '! file /etc/apache2/mods-enabled/headers.load'"
  }

 if $apache[mod_userdir] == 1 {
      exec { "enable-apache-userdir":
        user        => root,
        command     => "a2enmod userdir",
        notify      => Service["apache2"],
        require     => Class["apache::packages"],
        onlyif      => "sh -c '! file /etc/apache2/mods-enabled/userdir.conf'"
      }
  } else {
      exec { "disable-apache-userdir":
        user        => root,
        command     => "a2dismod userdir",
        notify      => Service["apache2"],
        require     => Class["apache::packages"],
        onlyif      => "sh -c 'file /etc/apache2/mods-enabled/userdir.conf'"
      }
  } 
  
 if $apache[mod_proxy] == 1 {
      exec { "enable-apache-proxy":
        user        => root,
        command     => "a2enmod proxy",
        notify      => Service["apache2"],
        require     => Class["apache::packages"],
        onlyif      => "sh -c '! file /etc/apache2/mods-enabled/proxy.load'"
      }
      exec { "enable-apache-proxy-http":
        user        => root,
        command     => "a2enmod proxy_http",
        notify      => Service["apache2"],
        require     => Class["apache::packages"],
        onlyif      => "sh -c '! file /etc/apache2/mods-enabled/proxy_http.load'"
      }
  } else {
      exec { "disable-apache-proxy":
        user        => root,
        command     => "a2dismod proxy",
        notify      => Service["apache2"],
        require     => Class["apache::packages"],
        onlyif      => "sh -c 'file /etc/apache2/mods-enabled/proxy.load'"
      }
      exec { "disable-apache-proxy-http":
        user        => root,
        command     => "a2dismod proxy_http",
        notify      => Service["apache2"],
        require     => Class["apache::packages"],
        onlyif      => "sh -c 'file /etc/apache2/mods-enabled/proxy_http.load'"
      }
  } 

  if $apache[mod_php] == 1 {
      exec { "enable-apache-php":
        user        => root,
        command     => "a2enmod php5",
        notify      => Service["apache2"],
        require     => Class["apache::packages", "php::packages"],
        onlyif      => "sh -c '! file /etc/apache2/mods-enabled/php5.load'"
      }
      include php
   }
   # unsure why, but I've seen an instance where PHP was uninstalled when it
   #   should not have been. Weird.
   #  else {
   #    exec { "disabled-apache-php":
   #      user        => root,
   #      command     => "a2dismod php5",
   #      notify      => Service["apache2"],
   #      require     => Class["apache::packages"],
   #      onlyif      => "sh -c 'file /etc/apache2/mods-enabled/php5.load'"
   #    }
   #    include php::absent
   # }

  if $apache[mod_wsgi] == 1 {
      exec { "enable-apache-wsgi":
        user        => root,
        command     => "a2enmod wsgi",
        notify      => Service["apache2"],
        require     => Class["apache::packages", "wsgi::packages"],
        onlyif      => "sh -c '! file /etc/apache2/mods-enabled/wsgi.load'"
      }
      include wsgi
   } else {
      exec { "disabled-apache-wsgi":
        user        => root,
        command     => "a2dismod wsgi",
        notify      => Service["apache2"],
        require     => Class["apache::packages"],
        onlyif      => "sh -c 'file /etc/apache2/mods-enabled/wsgi.load'"
      }
   }

   if $apache[mod_rewrite] == 1 {
      exec { "enable-apache-rewrite":
        user        => root,
        command     => "a2enmod rewrite",
        notify      => Service["apache2"],
        require     => Class["apache::packages"],
        onlyif      => "sh -c '! file /etc/apache2/mods-enabled/rewrite.load'"
      }
   } else {
      exec { "disabled-apache-rewrite":
        user        => root,
        command     => "a2dismod rewrite",
        notify      => Service["apache2"],
        require     => Class["apache::packages"],
        onlyif      => "sh -c 'file /etc/apache2/mods-enabled/rewrite.load'"
      }
   }

   # INFRA-298
   if $apache[mod_dav] == 1 {
      exec { "enable-apache-dav":
        user        => root,
        command     => "a2enmod dav",
        notify      => Service["apache2"],
        require     => Class["apache::packages"],
        onlyif      => "sh -c '! file /etc/apache2/mods-enabled/dav.load'"
      }
      exec { "enable-apache-davfs":
        user        => root,
        command     => "a2enmod dav_fs",
        notify      => Service["apache2"],
        require     => Class["apache::packages"],
        onlyif      => "sh -c '! file /etc/apache2/mods-enabled/dav_fs.load'"
      }
   } else {
      exec { "disabled-apache-dav":
        user        => root,
        command     => "a2dismod dav",
        notify      => Service["apache2"],
        require     => Class["apache::packages"],
        onlyif      => "sh -c 'file /etc/apache2/mods-enabled/dav.load'"
      }
      exec { "disabled-apache-davfs":
        user        => root,
        command     => "a2dismod dav_fs",
        notify      => Service["apache2"],
        require     => Class["apache::packages"],
        onlyif      => "sh -c 'file /etc/apache2/mods-enabled/dav_fs.load'"
      }
   }

  exec { "disable-apache-ssl-default-site":
    user        => root,
    command     => "a2dissite default-ssl",
    notify      => Service["apache2"],
    require     => Class["apache::packages"],
    onlyif      => "file /etc/apache2/sites-enabled/default-ssl"
  }
  
  file { "/etc/apache2/ports.conf":
    owner       => root,
    group       => root,
    mode        => 644,
    content     => template("apache/ports.conf.erb"),
  }
  
  file { "/etc/apache2/sites-enabled/vhosts.conf":
    owner       => root,
    group       => root,
    mode        => 644,
    content     => multi_source_template(
                     "apache/${hostname}-vhosts.conf.erb",
                     "apache/${profile}-vhosts.conf.erb",
                     "apache/vhosts.conf.erb"),
    require     => [
      Class["apache::packages"],
      File["/usr/local/bin/apache_accesslog"],
      File["/usr/local/bin/apache_errorlog"],
    ],
    notify      => Service["apache2"],
  }
  
  if $env == "test" or $env == "dev" {
    # INFRA-135: set apache log dir to 644 so non-root can read the logs
    file { "/var/log/apache2":
      ensure   => directory,
      owner    => root,
      group    => adm,
      mode     => 644,
      require  => Class["apache::packages"],
    }
  }
  
  # ubuntu seems to ship reasonable logrotate config already
}

class apache::services {
  service { "apache2":
    ensure  => running,
    enable  => true,
    require => Class["apache::packages", "apache::config"],
  }
  
  # INFRA-170: restart apache to make sure it picks up the new crl
  if $apache[https_active] == 1 {
    cron { "apache-restart-for-crl":
      command => "/etc/init.d/apache2 restart >/dev/null",
      user    => root,
      hour    => 02,
      minute  => 10,
    }
  } else {
    cron { "apache-restart-for-crl":
      command => "/etc/init.d/apache2 restart >/dev/null",
      ensure  => "absent",
      user    => root,
      hour    => 02,
      minute  => 10,
    }
  }
}

class apache::all_apps {
  file { "update_passenger_apps.sh":
    name    => "/usr/local/sbin/update_passenger_apps.sh",
    ensure  => absent,
  }

  file { "update_php_apps.sh":
    name    => "/usr/local/sbin/update_php_apps.sh",
    ensure  => absent,
  }

  file { "/etc/apache2/apps":
    ensure  => directory,
    mode    => 0755,
    owner   => root,
    group   => root,
    require => Class["apache::packages"]
  }

  include apache::apps
}

define apache::apps::config ($app_name, $app_user) {
  # with apache2.4 we could use IncludeOptional and we would not need fallback...

  # allow apps to specify a custom bit of config to put inside of their vhost,
  #   this is included from www-vhosts.conf.erb
  file { "/etc/apache2/apps/${app_name}-vhost-customization.conf":
    owner       => root,
    group       => root,
    mode        => 644,
    content     => multi_source_template(
                     "apache/vhost-customization-${hostname}-${app_name}.conf.erb",
                     "apache/vhost-customization-${env}-${app_name}.conf.erb",
                     "apache/vhost-customization-${app_name}.conf.erb",
                     "apache/vhost-customization.fallback.conf.erb"),
    require     => [
      Class["apache::all_apps"],
      File["/etc/apache2/apps"],
      User[$app_user],
    ],
    notify      => Service["apache2"],
  }
  
  file { "/etc/apache2/apps/${app_name}-global-customization.conf":
    ensure  => absent,
    require => File["/etc/apache2/apps"],
    notify  => Service["apache2"],
  }

  # the below is using exec {} instead of file {} to allow for symlinking

  exec { "/home/${app_user}/${app_name}":
    user        => root,
    command     => "mkdir -m 0755 /home/${app_user}/${app_name}",
    onlyif      => "sh -c '! file /home/${app_user}/${app_name}'",
    require     => User[$app_user],
  }

  exec { "chown /home/${app_user}/${app_name}":
    user        => root,
    command     => "chown $app_user /home/${app_user}/${app_name}",
    require     => User[$app_user],
    subscribe   => Exec["/home/${app_user}/${app_name}"],
    refreshonly => true,
  }

  exec { "/home/${app_user}/${app_name}/current":
    user        => root,
    command     => "mkdir -m 0755 /home/${app_user}/${app_name}/current",
    onlyif      => "sh -c '! file /home/${app_user}/${app_name}/current'",
    require     => Exec["/home/${app_user}/${app_name}"],
  }

  exec { "chown /home/${app_user}/${app_name}/current":
    user        => root,
    command     => "chown $app_user /home/${app_user}/${app_name}/current",
    require     => User[$app_user],
    subscribe   => Exec["/home/${app_user}/${app_name}/current"],
    refreshonly => true,
  }

  exec { "/home/${app_user}/${app_name}/current/public":
    user        => root,
    command     => "mkdir -m 0755 /home/${app_user}/${app_name}/current/public",
    onlyif      => "sh -c '! file /home/${app_user}/${app_name}/current/public'",
    require     => Exec["/home/${app_user}/${app_name}/current"],
  }

  exec { "chown /home/${app_user}/${app_name}/current/public":
    user        => root,
    command     => "chown $app_user /home/${app_user}/${app_name}/current/public",
    require     => User[$app_user],
    subscribe   => Exec["/home/${app_user}/${app_name}/current/public"],
    refreshonly => true,
  }

  exec { "/var/www/${app_name}":
    user        => root,
    command     => "ln -s /home/${app_user}/${app_name}/current/public /var/www/${app_name}",
    onlyif      => "sh -c '! file /var/www/${app_name}'",
    require     => Class["apache::packages"],
    notify      => Service["apache2"],
  }

  # exec { "chown /var/www/${app_name}":
  #   user        => root,
  #   command     => "chown $app_user /var/www/${app_name}",
  #   require     => User[$app_user],
  #   subscribe   => Exec["/var/www/${app_name}"],
  #   refreshonly => true,
  #   notify      => Service["apache2"],
  # }
}

define apache::apps::deleted_config ($app_name) {
  # INFRA-228: todo, delete the unused configs
  file { "/etc/apache2/apps/${app_name}-vhost-customization.conf":
    ensure      => absent,
    require     => [
      Class["apache::all_apps"],
      File["/etc/apache2/apps"],
    ],
    notify      => Service["apache2"],
  }

  file { "/etc/apache2/apps/${app_name}-global-customization.conf":
    ensure  => absent,
    require => File["/etc/apache2/apps"],
    notify  => Service["apache2"],
  }

  file { "/var/www/${app_name}":
    ensure => absent,
    require => Class["apache::packages"],
  }
}

class apache::style {
  $doc_root = $apache[DocumentRoot]
  $all_css_file = "$doc_root/example-all.css"
  file { "$all_css_file":
    ensure  => "file",
    owner   => "root",
    group   => "root",
    mode    => 644,
    source  => "puppet://puppet/modules/apache/example-all.css",
    require => Class["apache::packages"],
  }
}

class apache::app_index {
  # writes an index.html into the docroot
  if $apache[app_index] == 1 {
    $doc_root = $apache[DocumentRoot]
    $index_file = "$doc_root/index.html"
    file { "$index_file":
      content => template("apache/app_index.html.erb"),
      owner   => "root",
      group   => "root",
      mode    => 644,
      require => Class["apache::packages"], # for creating /var/www
    }

    include apache::style
  }
}

class apache::favicon {
  # writes a favicon into the docroot
  $doc_root = $apache[DocumentRoot]
  $favicon_file = "$doc_root/favicon.ico"
  file { "$favicon_file":
    source  => "puppet://puppet/modules/apache/favicon.ico",
    owner   => "root",
    group   => "root",
    mode    => 644,
    require => Class["apache::packages"], # for creating /var/www
  }
}

class apache::robots_txt {
  # writes a robots.txt into the docroot
  $doc_root = $apache[DocumentRoot]
  $robot_file = "$doc_root/robots.txt"
  file { "$robot_file":
      source  => "puppet://puppet/modules/apache/robots.txt",
      owner   => "root",
      group   => "root",
      mode    => 644,
      require => Class["apache::packages"], # for creating /var/www
  }
}

class apache::ca {
  # writes docroot contents exposing key pki::ca details
  $doc_root = $apache[DocumentRoot]
  $header_file = "$doc_root/.HEADER.html"
  file { "$header_file":
      source  => "puppet://puppet/modules/apache/ca_header.html",
      owner   => "root",
      group   => "root",
      mode    => 644,
      require => Class["apache::packages"], # for creating /var/www
  }

  $index_file = "$doc_root/index.html"
  file { "$index_file":
      ensure  => "absent",
  }

  $ca_pem_file = "$doc_root/ca.pem"
  file { "$ca_pem_file":
      ensure  => "link",
      target  => "/usr/share/ca-certificates/local/ca.pem",
      owner   => "root",
      group   => "root",
      mode    => 644,
      require => Class["apache::packages"], # for creating /var/www
  }

  $crl_pem_file = "$doc_root/crl.pem"
  file { "$crl_pem_file":
      ensure  => "link",
      target  => "/usr/share/ca-certificates/local/crl.pem",
      owner   => "root",
      group   => "root",
      mode    => 644,
      require => Class["apache::packages"], # for creating /var/www
  }

  # INFRA-201
  file { "/etc/apache2/conf.d/pem-mime-type.conf":
    source  => "puppet://puppet/modules/apache/pem-mime-type.conf",
    owner   => "root",
    group   => "root",
    mode    => 644,
    require => Class["apache::packages"], # for creating /var/www
    notify  => Service["apache2"],
  }

  include apache::style
}

class apache::htpasswd {
  file { "/etc/sys":
    ensure  => directory,
    mode    => 0755,
    owner   => root,
    group   => root,
  }
  file { "/etc/sys/htpasswd":
    ensure  => file,
    mode    => 0644,
    owner   => root,
    group   => root,
    source  => ["puppet://puppet/modules/apache/htpasswd.${hostname}",
                "puppet://puppet/modules/apache/htpasswd.${env}",
                "puppet://puppet/modules/apache/htpasswd.${profile}",
                "puppet://puppet/modules/apache/htpasswd.fallback"],
    require => File["/etc/sys"],
  }
}

class apache {
  include apache::packages, apache::config, apache::services
  include apache::all_apps
  include apache::app_index, apache::htpasswd, apache::favicon, apache::robots_txt
  # apache:: ca is not included here and should be included seperately
}
