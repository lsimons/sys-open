# http://codex.wordpress.org/Installing_WordPress
# http://codex.wordpress.org/Create_A_Network
# http://codex.wordpress.org/Administration_Over_SSL
# http://codex.wordpress.org/Installing/Updating_WordPress_with_Subversion
# https://github.com/OldExample/sys/tree/master/wordpress

class wp::packages {
  if ! defined(Package['git-core'])             { package { 'git-core':             ensure => "${package_ensure}" } }
  
  # php is included from apache module, make sure mod_php: 1
}

class wp::www {
  # this setup follows roughly the same as used for ruby on rails / capistrano
  # (see medenc for an example), with
  $wp_user          = "wp"
  $wp_group         = "wp"
  $wp_repo          = "https://github.com/WordPress/WordPress.git"
  $www_group        = "www-data"
  
  $app_root         = "/home/$wp_user/www"
  $app_config       = "$app_root/wp-config.php"
  $app_sunrise      = "$app_root/sunrise.php"
  $app_advanced_cache = "$app_root/advanced-cache.php"
  $app_cache_config = "$app_root/wp-cache-config.php"
  $app_current      = "$app_root/current"     # a symlink to releases/$releaseversion
  $doc_root         = "${apache[DocumentRoot]}"  # /home/wp/www/current/public
  $app_docs         = "$app_root/docs"        # /home/wp/www/cdocs
  $app_repo         = "$app_root/repo"
  $app_releases     = "$app_root/releases"
  $app_release_0    = "$app_root/releases/0"
  $themes           = "$app_root/themes"      # for installing custom themes
  $plugins          = "$app_root/plugins"     # for installing custom plugins
  $languages        = "$app_root/languages"   # for installing qtranslate language files
  $uploads          = "$app_root/uploads"     # for user uploads (web server writeable)
  $cache            = "$app_root/cache"       # for supercache (web server writeable)
  $multi_uploads    = "$app_root/multi_uploads" # for user uploads to multisite blogs (web server writeable)
  
  
  # The wp-install.sh script is set up for you so you can install and select a particular release,
  # which also links in all themes and plugins. So the simplistic process becomes:
  
  # 1) add/update any themes you want:
  #   rsync -a my-theme/ wp@wp.old.example.org:/home/wp/www/themes/my-theme/
  # 2) add/update any plugins you want:
  #   rsync -a my-plugin/ wp@wp.old.example.org:/home/wp/www/plugins/my-plugin/
  # 3) upgrade wordpress to latest release:
  #   ssh wp@wp.old.example.org /home/wp/www/wp-install.sh 3.4
  
  # Note that not having the specific wordpress version inside puppet is a concious choice
  # right now. We could do it of course, by invoking wp-install.sh. But, wp-install.sh also
  # does a few other things (linking in the plugins and themes), so I figure for now this is
  # nice and concise and safe.
  
  file { "$app_root":
    ensure  => "directory",
    owner   => "$wp_user",
    group   => "$www_group",
    mode    => 750,
    require => Class["users"],
  }
  
  file { "$themes":
    ensure  => "directory",
    owner   => "$wp_user",
    group   => "$www_group",
    mode    => 750,
    require => File["$app_root"],
  }

  file { "$plugins":
    ensure  => "directory",
    owner   => "$wp_user",
    group   => "$www_group",
    mode    => 750,
    require => File["$app_root"],
  }

  file { "$uploads":
    ensure  => "directory",
    owner   => "$wp_user",
    group   => "$www_group",
    mode    => 770,
    require => File["$app_root"],
  }

  file { "$multi_uploads":
    ensure  => "directory",
    owner   => "$wp_user",
    group   => "$www_group",
    mode    => 770,
    require => File["$app_root"],
  }

  file { "$cache":
    ensure  => "directory",
    owner   => "$wp_user",
    group   => "$www_group",
    mode    => 770,
    require => File["$app_root"],
  }

  file { "$app_releases":
    ensure  => "directory",
    owner   => "$wp_user",
    group   => "$www_group",
    mode    => 750,
    require => File["$app_root"],
  }

  file { "$app_release_0":
    ensure  => "directory",
    owner   => "$wp_user",
    group   => "$www_group",
    mode    => 750,
    require => File["$app_releases"],
  }
  
  file { "$app_release_0/public":
    ensure  => "directory",
    owner   => "$wp_user",
    group   => "$www_group",
    mode    => 750,
    require => File["$app_release_0"],
  }
  
  file { "$app_docs":
    ensure  => "directory",
    owner   => "$wp_user",
    group   => "$www_group",
    mode    => 750,
    require => File["$app_root"],
  }
  
  exec { "link-default-install":
    unless  => "test -e $app_current",
    command => "ln -s $app_release_0 $app_current",
    require => File["$app_release_0"],
  }

  file { "$app_config":
    ensure  => "file",
    owner   => "$wp_user",
    group   => "$www_group",
    mode    => 440,
    require => [File["$app_root"], Class["apache::packages"]],
    content => template("wp/wp-config.php.erb"),
  }

  file { "$app_sunrise":
    ensure  => "file",
    owner   => "$wp_user",
    group   => "$www_group",
    mode    => 440,
    require => [File["$app_root"], Class["apache::packages"]],
    source => "puppet:///modules/wp/sunrise.php",
  }

  # supercache does not play well with qtranslate :-(
  file { "$app_advanced_cache":
    ensure  => "absent",
    require => [File["$app_root"], Class["apache::packages"]],
    content => template("wp/advanced-cache.php.erb"),
  }

  file { "$app_cache_config":
    ensure  => "absent",
    require => [File["$app_root"], Class["apache::packages"]],
    content => template("wp/wp-cache-config.php.erb"),
  }
  # file { "$app_advanced_cache":
  #   ensure  => "file",
  #   owner   => "$wp_user",
  #   group   => "$www_group",
  #   mode    => 440,
  #   require => [File["$app_root"], Class["apache::packages"]],
  #   content => template("wp/advanced-cache.php.erb"),
  # }
  # 
  # file { "$app_cache_config":
  #   ensure  => "file",
  #   owner   => "$wp_user",
  #   group   => "$www_group",
  #   mode    => 440,
  #   require => [File["$app_root"], Class["apache::packages"]],
  #   content => template("wp/wp-cache-config.php.erb"),
  # }

  file { "$app_root/wp-install.sh":
    ensure  => file,
    content => template("wp/wp-install.sh.erb"),
    owner   => "$wp_user",
    group   => "$wp_group",
    mode    => 700,
    require => Package["git-core"],
  }
  
  exec { "enable-mod-rewrite":
    user        => root,
    command     => "a2enmod rewrite",
    notify      => Service["apache2"],
    require     => Class["apache::packages"],
    onlyif      => "sh -c '! file /etc/apache2/mods-enabled/rewrite.load'"
  }

}

class wp {
  include wp::packages, wp::www
}
