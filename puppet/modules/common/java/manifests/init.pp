class java::packages {
  package { "openjdk-7-jre-headless":
    ensure => "${package_ensure}",
  }
  
  package { ["openjdk-6-jre-headless", "openjdk-6-jre-lib"]:
    ensure => "absent",
  }
}

class java::alternatives {
  exec { "update-java-alternatives":
    user        => root,
    path        => "/usr/sbin",
    command     => "update-java-alternatives -s java-1.7.0-openjdk-amd64",
    require     => Class["java::packages"],
    subscribe   => Package["openjdk-7-jre-headless"],
    refreshonly => true,
  }
}

class java {
  include java::packages, java::alternatives
}
