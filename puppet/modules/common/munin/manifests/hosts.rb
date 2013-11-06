# helper that defines munin::server::config based on systems.yml

hostclass :"munin::hosts" do
  management = scope.lookupvar("management")
  exclude = management['exclude_environments']

  nodes = YAML::load( File.open( '/etc/sys/puppet/systems.yml' ))
  hosts = []

  nodes.each do |host, params|
    env = params['env']
    if env == "deleted" or exclude.include? env
      next
    end

    node_config = YAML::load( %x[ /etc/sys/puppet-node.rb  #{host} ])
    if node_config.has_key?('parameters')
      params = node_config['parameters']
      if params.has_key?('monitor')
        monitor = params['monitor']
        if monitor == 1 
          hosts.push(host)
        end
      end
    end
  end
  
  monitor_hosts = {
    "munin::hosts::config" => {
      "monitor_hosts" => hosts
    }
  }

  create_resources(['munin::server::config', monitor_hosts])
end
