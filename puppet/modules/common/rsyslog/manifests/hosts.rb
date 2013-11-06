# helper that defines rsyslog::config based on systems.yml

hostclass :"rsyslog::hosts" do
  management = scope.lookupvar("management")
  exclude = management['exclude_environments']

  nodes = YAML::load( File.open( '/etc/sys/puppet/systems.yml' ))
  hosts = []
  nodes.each do |host, params|
    env = params['env']
    if env == "deleted" or exclude.include? env
      next
    end

    hosts.push(host)
  end

  rsyslog_clients = {
    "rsyslog::hosts::config" => {
      "rsyslog_clients" => hosts
    }
  }

  create_resources(['rsyslog::config', rsyslog_clients])
end
