class deploy {
  # helper script to conveniently install debian packages via SSH
  if $env == "test" or $env == "dev" or $env == "local" {
    file { "/usr/local/bin/ddeploy":
      source  => "puppet://puppet/modules/deploy/ddeploy",
      owner   => "root",
      group   => "root",
      mode    => 755,
    }
  }
}