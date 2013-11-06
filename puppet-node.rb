#!/usr/bin/env ruby

# This is a simple external node classifier for puppet that reads /etc/sys/puppet/*.yml

fqdn = ARGV.shift
node = fqdn # .split(/\./).first
system("logger -t puppet-node -p daemon.info 'classifying #{fqdn}'")
begin
  require 'yaml'

  ### extend Hash with deep_merge method
  class Hash
    # Merges self with another hash, recursively.
    def deep_merge(other)
      target = dup
    
      other.keys.each do |key|
        if other[key].is_a? Hash and self[key].is_a? Hash
          target[key] = target[key].deep_merge(other[key])
          next
        end
      
        target[key] = other[key]
      end
    
      target
    end
  end


  ### read environment and command line
  config_yml = ENV['GLOBAL_CONFIG']
  config_yml ||= '/etc/sys/puppet/config.yml'

  systems_yml = ENV['SERVER_CONFIG']
  systems_yml ||= '/etc/sys/puppet/systems.yml'

  profile_yml = ENV['PROFILE_CONFIG']
  profile_yml ||= '/etc/sys/puppet/profiles.yml'

  environments_yml = ENV['GLOBAL_CONFIG']
  environments_yml ||= '/etc/sys/puppet/environments.yml'

  apps_yml = ENV['APP_CONFIG']
  apps_yml ||= '/etc/sys/puppet/apps.yml'

  raise RuntimeError, "usage: puppet-node.rb servername" if node.nil?


  ### read YAML
  global_defaults = YAML::load_file(config_yml)

  systems = YAML::load_file(systems_yml)
  unless systems.has_key?(node)
    exit 1
  end

  profiles = YAML::load_file(profile_yml)

  environments    = YAML::load_file(environments_yml)

  apps = YAML::load_file(apps_yml)


  ### pick apart YAML into the key information
  system                = systems[node]
  raise RuntimeError, "#{node} not found in #{systems_yml}" unless system != nil

  if system.has_key?('profile')
    profile = system['profile']
  else
    profile = 'base'
  end
  raise RuntimeError, "#{profile} not found in #{profile_yml}" unless profiles.has_key?(profile)

  profile_config  = profiles[profile]
  raise RuntimeError, "#{profile} has no config in #{profile_yml}" unless profile_config != nil
  if profiles.has_key?('default')
    default_profile_config = profiles['default']
  else
    default_profile_config = {}
  end

  if system.has_key?('env')
    env = system['env']
  else
    env = 'live'
  end

  if environments.has_key?(env)
    environment_defaults  = environments[env]
  else
    environment_defaults  = {}
  end

  if apps.has_key?(profile)
    app_config = apps[profile]
  else
    app_config = {}
  end

  if apps.has_key?("deleted")
    deleted_apps = apps["deleted"]
    if not deleted_apps.has_key?("java_apps")
      deleted_apps["java_apps"] = []
    end
    if not deleted_apps.has_key?("passenger_apps")
      deleted_apps["passenger_apps"] = []
    end
    if not deleted_apps.has_key?("wsgi_apps")
      deleted_apps["wsgi_apps"] = []
    end
    if not deleted_apps.has_key?("php_apps")
      deleted_apps["php_apps"] = []
    end
    app_config["deleted_apps"] = deleted_apps
  else
    app_config["deleted_apps"] = {
      "java_apps"      => [],
      "passenger_apps" => [],
      "wsgi_apps"      => [],
      "php_apps"       => [],
    }
  end

  ### merge configuration into one
  # note order of .deep_merge() calls matters:
  #   overrides go inside-out
  system = global_defaults.deep_merge(
      default_profile_config.deep_merge(
          profile_config.deep_merge(
              environment_defaults.deep_merge(
                  app_config.deep_merge(
                      system
                  )
              )
          )
      )
  )

  raise RuntimeError, "classes not found for system #{node}" unless system.has_key?('classes')
  classes = system['classes']
  system.delete('classes')

  ### sanity check to make sure 'core' variables always have a value
  if not system.has_key?('env')
    system['env'] = 'live'
  end
  if not system.has_key?('environment')
    system['environment'] = 'production'
  end
  if not system.has_key?('domain')
    system['domain'] = 'local'
  end
  if not system.has_key?('profile')
    system['profile'] = 'base'
  end
  if not system.has_key?('server_admin_email')
    system['server_admin_email'] = 'root@localhost'
  end

  if not system.has_key?('passenger_apps')
    system['passenger_apps'] = []
  end
  if not system.has_key?('wsgi_apps')
    system['wsgi_apps'] = []
  end
  if not system.has_key?('php_apps')
    system['php_apps'] = []
  end
  if not system.has_key?('java_apps')
    system['java_apps'] = []
  end

  if system.has_key?('management')
    management = system['management']
    if management.has_key?('exclude_environments')
      exclude = management['exclude_environments']
      env = system['env']
      if exclude.include? env
        raise RuntimeError, "#{node} is in environment #{env} which is on the list of excluded environments"
      end
    else
      system['management'] = { "exclude_environments" => [] }
    end
  else
    system['management'] = { "exclude_environments" => [] }
  end

  ### dump completed config to stdout
  puppet = {
    'classes'     => classes,
    'parameters'  => system,
  }

  puts YAML::dump(puppet)
rescue Exception => e
  system("logger -t puppet-node -p daemon.crit 'error classifying #{fqdn}: #{e.message}'")
  raise
else
  system("logger -t puppet-node -p daemon.info 'classified #{fqdn}'")
end
