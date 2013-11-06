class php::packages {
  define heldpackage ($package = $title) {
    exec { "install-${package}":
      command => "apt-get install ${package}",
      onlyif => "bash -c '! dpkg --get-selections | awk \"/^${package}\\W+(install|hold)/{print \$1}\" | grep ${package}'",
      notify => Exec["hold-${package}"],
      logoutput => "true",
    }
    
    # http://serverfault.com/questions/370266/puppet-using-ensure-with-package-version-and-held
    exec { "hold-${package}":
      command => "echo ${package} hold | dpkg --set-selections",
      refreshonly => "true",
      logoutput => "true",
    }
  }

  if $env == "project1" {
    # https://example.atlassian.net/wiki/display/INFRA/project1+Measurement+Service+Run+Book
    heldpackage { [
            "libapache2-mod-php5",
            "php5-common",
            "php5-fpm",
            "php5",
            "php5-dev",
            "php5-curl",
            "php5-mysql",
            "php5-cli",
            "php5-gd",
            "php-log",
            "php-pear",
          ]:
    }
  } else {
    package { [
        "libapache2-mod-php5",
        "php5-common",
        "php5-fpm",
        "php5",
        "php5-dev",
        "php5-curl",
        "php5-mysql",
        "php5-cli",
        "php5-gd",
        "php-log",
        "php-pear",
      ]:
      ensure => "${package_ensure}",
    }
  }
}

class php {
  include php::packages, mysql::client::packages
}

class php::absent {
  package { [
      "libapache2-mod-php5",
      "php5-common",
      "php5-fpm",
      "php5",
      "php5-dev",
      "php5-curl",
      "php5-mysql",
      "php5-cli",
      "php5-gd",
      "php-log",
      "php-pear",
    ]:
    ensure => absent,
  }
}
