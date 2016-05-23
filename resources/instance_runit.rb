#
# Cookbook Name:: memcached
# resource:: instance
#
# Copyright 2009-2016, Chef Software, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

provides :memcached_instance

property :instance_name, String, name_attribute: true
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

action :create do
  include_recipe 'runit'
  include_recipe 'memcached::_package'

  # Disable the default memcached service to avoid port conflicts + wasted memory
  disable_default_memcached_instance

  # cleanup default configs to avoid confusion
  remove_default_memcached_configs

  runit_service memcached_instance_name do
    run_template_name 'memcached'
    default_logger true
    cookbook new_resource.template_cookbook
    options(
      ulimit: new_resource.ulimit,
      user: new_reousrce.user,
      cli_options: cli_options
    )
  end
end

action :remove do
  runit_service memcached_instance_name do
    action [:stop, :disable]
  end
end