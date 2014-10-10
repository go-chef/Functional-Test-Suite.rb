require 'mixlib/shellout'
require 'librarian/chef/environment'
require 'librarian/action/resolve'
require 'librarian/action/install'
require_relative 'machine'
require 'chef/config'

module Provisioner
  extend self
  def repo_path
    File.expand_path('../..', __FILE__)
  end
  def create_goiardi
    create_server('goiardi', 'goiardi')
    clean
    write_configs
    vendorize_cookbooks
  end
  def create_server(name, recipe = 'chef')
    server =  Machine.new(name)
    server.start
    server.run_recipe("#{repo_path}/recipes/#{recipe}.rb")
    sleep 10
  end
  def write_configs
    server =  Machine.new('goiardi')
    FileUtils.mkdir_p('keys')
    FileUtils.mkdir_p('etc')
    %w{admin.pem  chef-validator.pem}.each do |key|
      File.open("keys/#{key}", 'w') do |f|
        f.write(server.read_file("/etc/goiardi/#{key}"))
      end
    end
    File.open("#{repo_path}/keys/secret", 'w') do |f|
      f.write(generate_secret)
    end
    File.open("#{repo_path}/etc/knife.rb", 'w') do |f|
      f.write(knife_config(server))
    end
    Chef::Config[:data_bag_path] = "#{repo_path}/data_bags"
  end
  def clean
    FileUtils.rm_rf("#{repo_path}/keys")
    FileUtils.rm_rf("#{repo_path}/etc")
    FileUtils.rm_rf("#{repo_path}/cookbooks")
  end
  def generate_secret
    cmd = Mixlib::ShellOut.new("openssl rand -base64 512 | tr -d '\r\n'")
    cmd.run_command
    fail cmd.stderr unless cmd.exitstatus.zero?
    cmd.stdout
  end
  def delete_server(name)
    server =  Machine.new(name)
    server.destroy
    clean
  end
  def knife(klass, *args)
    Chef::Config.from_file "#{repo_path}/etc/knife.rb"
    klass.load_deps
    plugin = klass.new
    plugin.name_args = args
    yield plugin.config if block_given?
    plugin.run
  end

  def vendorize_cookbooks
    env = Librarian::Chef::Environment.new( project_path:  repo_path)
    env.config_db.local["path"] = "#{repo_path}/cookbooks"
    Librarian::Action::Resolve.new(env).run
    Librarian::Action::Install.new(env).run
  end
  def knife_config(server)
  <<EOF
chef_server_url 'http://#{server.ct.ip_addresses.first}:4646'
node_name 'admin'
client_key '#{repo_path}/keys/admin.pem'
validation_key '#{repo_path}/keys/chef-validator.pem'
EOF
  end
end
