# helper that defines nagios::puppetconfig for each system in systems.yml based on _its_ puppet configuration

hostclass :"nagios::hosts" do
  management = scope.lookupvar("management")
  exclude = management['exclude_environments']

  nodes = YAML::load( File.open( '/etc/sys/puppet/systems.yml' ))
  
  monitor_hosts = {}
  
  nodes.each do |host, params|
    env = params['env']

    monitor = 0
    if env != "deleted" and not exclude.include? env
      node_config = YAML::load( %x[ /etc/sys/puppet-node.rb  #{host} ])
      if node_config.has_key?('parameters')
        params = node_config['parameters']
        if params.has_key?('monitor')
          monitor = params['monitor']
        end
      end
    end

    if monitor == 1 
      host_classes = node_config['classes']
      if host_classes == nil
        host_classes = []
      end
      host_params = node_config['parameters']
      if host_params == nil
        host_params = {}
      end

      monitor_hosts["nagios::hosts::cfg::#{host}"] = {
        "host"         => host,
        "host_classes" => host_classes,
        "host_params"  => host_params,
      }
    else # monitor == 0
      file "/etc/sys/puppet/modules/common/nagios/files/nagios3/conf.d/#{host}.cfg",
          :ensure => "absent"
    end
  end
  
  # File.open( '/tmp/monitor_hosts.yml', 'w' ) do |out|
  #   YAML.dump( monitor_hosts, out )
  # end
  
  create_resources(['nagios::puppetconfig', monitor_hosts])
end
