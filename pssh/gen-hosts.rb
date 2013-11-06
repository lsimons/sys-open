#!/usr/bin/env ruby

# This is a simple script that dumps /etc/sys/puppet/systems.yml into a few hosts.txt files that pssh can use

require 'yaml'

systems = YAML::load_file('../puppet/systems.yml')

all_hosts = []
by_environment = {}

systems.each { |name, config|
  env = config['env']
  
  if env != "deleted" and env != "local"
    all_hosts.push(name)
  end
  if not by_environment.has_key?(env)
    by_environment[env] = []
  end
  by_environment[env].push(name)
}

File.open("all.hosts", "w") { |f|
  all_hosts.each { |h|
    f.write("#{h}\n")
  }
}
puts "wrote all.hosts\n"

by_environment.each { |env, hosts|
  File.open("#{env}.hosts", "w") { |f|
    hosts.each { |h|
      f.write("#{h}\n")
    }
  }
  puts "wrote #{env}.hosts\n"
}

system("ssh-keyscan -f all.hosts > known_hosts 2>/dev/null")
puts "wrote known_hosts\n"
