hostclass :"apache::apps" do
  env = scope.lookupvar("env")
  domain = scope.lookupvar("domain")

  app_configurations = {}
  deleted_app_configurations = {}
  
  all_deleted_apps = scope.lookupvar("deleted_apps")
  all_apps = YAML::load( File.open( '/etc/sys/puppet/apps.yml' ))
  profile = scope.lookupvar("profile")
  if all_apps.has_key?(profile)
    profile_apps = all_apps[profile]
  else
    profile_apps = []
  end

  app_types = ["php", "passenger", "wsgi"] #, "java"]
  app_types.each do |app_type|
    if profile_apps.has_key?("#{app_type}_apps")
      apps = profile_apps["#{app_type}_apps"]
    else
      apps = []
    end
    deleted_apps = all_deleted_apps["#{app_type}_apps"]
    
    apps.each do |app|
      if not app.has_key?('AppName')
        raise "application without AppName"
      end
      app_name = app['AppName']
      if not app.has_key?('User')
        raise "application without User"
      end
      app_user = app['User']
      deleted_apps.each do |deleted_app|
        if not deleted_app.has_key?('AppName')
          raise "application without AppName"
        end
        deleted_app_name = deleted_app['AppName']
        if app_name == deleted_app_name
          raise "application #{app_name} is also in deleted section"
        end
      end
    
      fqdn = "#{app_name}.#{env}.#{domain}"
      app_configurations["apache::apps::config::#{app_type}::#{fqdn}"] = {
        "app_name" => app_name,
        "app_user" => app_user,
      }
    end
  
    deleted_apps.each do |app|
      if not app.has_key?('AppName')
        raise "application without AppName"
      end
      app_name = app['AppName']

      fqdn = "#{app_name}.#{env}.#{domain}"
      deleted_app_configurations["apache::apps::deleted_config::#{app_type}::#{fqdn}"] = {
        "app_name" => app_name,
      }
    end
  end

  create_resources(["apache::apps::config", app_configurations])
  create_resources(["apache::apps::deleted_config", deleted_app_configurations])
end
