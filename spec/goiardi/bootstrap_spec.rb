require 'spec_helper'
require 'chef/knife/bootstrap'
require 'chef/knife/cookbook_upload'

describe 'Bootstrap and search' do
  let(:node_ip) do
    LXC::Container.new('node1').ip_addresses.first
  end
  before(:all) do
    knife Chef::Knife::CookbookUpload do |config|
      config[:cookbook_path] = "#{repo_path}/cookbooks"
      config[:all] = true
    end
  end
  it 'should bootstrap successfully' do
    knife Chef::Knife::Bootstrap, node_ip do |config|
      config[:ssh_user] = 'ubuntu'
      config[:ssh_password] = 'ubuntu'
      config[:ssh_port] = 22
      config[:chef_node_name] = 'JimiHendrix'
      config[:bootstrap_template] = 'chef-full'
      config[:distro] = 'chef-full'
      config[:use_sudo] = true
      config[:use_sudo_password] = true
      config[:run_list] = ['recipe[apache2]']
      config[:host_key_verify] = false
    end
    expect(Chef::Node.load('JimiHendrix').ipaddress).to eq(node_ip)
  end
end
