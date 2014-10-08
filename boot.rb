#!/usr/bin/env ruby

require 'lxc'
require 'lxc/extra'
require 'chef/lxc'
require 'chef'
require 'chef/client'
require 'chef/config'
require 'chef/log'
require 'fileutils'
require 'tempfile'
require 'chef/providers'
require 'chef/resources'
require 'digest/md5'

class Machine

  attr_reader :ct

  def initialize(name)
    @ct = LXC::Container.new(name)
  end

  def read_file(path)
    ct.execute do
      File.read(path)
    end
  end

  def run_recipe(file)
    recipe_text = ::File.read(file)
    Chef::Config[:solo] = true
    client.ohai.load_plugins
    ct.execute do
      ios = ObjectSpace.each_object(IO).to_a
      client.run_ohai
      client.load_node
      client.build_node
      run_context = Chef::RunContext.new(client.node, {}, client.events)
      recipe = Chef::Recipe.new("(chef-lxc cookbook)", "(chef-lxc recipe)", run_context)
      recipe.instance_eval(recipe_text, '/foo/bar.rb', 1)
      runner = Chef::Runner.new(run_context)
      runner.converge
      ( ObjectSpace.each_object(IO).to_a - ios ).each do |io|
        io.close unless io.closed?
      end
      nil
    end
  end

  def client
    @client ||= Class.new(Chef::Client) do
      def run_ohai
        ohai.run_plugins
      end
    end.new
  end

  def start
    unless ct.defined?
      ct.create('download', nil, {}, 0, %w{-a amd64 -r trusty -d ubuntu})
    end
    unless ct.running?
      ct.start
      sleep 1 while ct.ip_addresses.empty?
    end
  end

  def destroy
    ct.stop if ct.running?
    ct.destroy if ct.defined?
  end
  def knife_config
<<EOF
chef_server_url 'http://#{ct.ip_addresses.first}:4646'
client_name 'admin'
client_key '../keys/admin.pem'
EOF
  end

  def setup
    FileUtils.mkdir_p('keys')
    FileUtils.mkdir_p('etc')
    %w{admin.pem  chef-validator.pem}.each do |key|
      File.open("keys/#{key}", 'w') do |f|
        f.write(read_file("etc/goiardi/#{key}"))
      end
    end
    File.open('etc/knife.rb', 'w') do |f|
      f.write(knife_config)
    end
  end
  def clean
    FileUtils.rm_rf('keys')
    FileUtils.rm_rf('etc')
  end
end

machine =  Machine.new('goiardi')
machine.setup
machine.start
machine.run_recipe('recipes/goiardi.rb')
machine.client
machine.destroy

