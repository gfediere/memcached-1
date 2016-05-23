provides :memcached_instance, platform: 'ubuntu' do |node|
  node['platform_version'].to_f < 15.10
end

property :instance_name, String, name_property: true
property :memory, [Integer, String], default: 64
property :port, [Integer, String], default: 11_211
property :udp_port, [Integer, String], default: 11_211
property :listen, String, default: '0.0.0.0'
property :maxconn, [Integer, String], default: 1024
property :user, String, default: lazy { service_user }
property :threads, [Integer, String]
property :max_object_size, String, default: '1m'
property :experimental_options, Array, default: []
property :ulimit, [Integer, String], default: 1024
property :template_cookbook, String, default: 'memcached'
property :disable_default_instance, [TrueClass, FalseClass], default: true

action :start do
  create_init

  service memcached_instance_name do
    supports restart: true, status: true
    action :start
  end
end

action :stop do
  service memcached_instance_name do
    supports status: true
    action :stop
    only_if { ::File.exist?("/etc/init/#{memcached_instance_name}.conf") }
  end
end

action :restart do
  action_stop
  action_start
end

action :enable do
  service memcached_instance_name do
    supports status: true
    action :enable
    only_if { ::File.exist?("/etc/init/#{memcached_instance_name}.conf") }
  end
end

action :disable do
  service memcached_instance_name do
    supports status: true
    action :disable
    only_if { ::File.exist?("/etc/init/#{memcached_instance_name}.conf") }
  end
end

action_class.class_eval do
  def create_init
    include_recipe 'memcached::_package'

    # Disable the default memcached service to avoid port conflicts + wasted memory
    disable_default_memcached_instance

    # remove the default init script if our service is also named
    # memcached so we don't have both an upstart script and an sys-v script
    file '/etc/init.d/memcached' do
      action :delete
      only_if { new_resource.name == 'memcached' }
    end

    # cleanup default configs to avoid confusion
    remove_default_memcached_configs

    # service resource for notification
    service memcached_instance_name do
      action :nothing
    end

    template "/etc/init/#{memcached_instance_name}.conf" do
      source 'init_upstart.erb'
      variables(
        instance: memcached_instance_name,
        ulimit: new_resource.ulimit,
        cli_options: cli_options
      )
      cookbook 'memcached'
      notifies :restart, "service[#{memcached_instance_name}]", :immediately
      owner 'root'
      group 'root'
      mode '0644'
    end
  end
end