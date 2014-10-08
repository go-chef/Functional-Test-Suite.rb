require 'spec_helper'
require 'chef/knife/cookbook_create'
require 'chef/knife/cookbook_show'
require 'chef/knife/cookbook_delete'
require 'chef/knife/cookbook_upload'

describe 'Cookbook' do
  it '#upload' do
    expect do
      knife Chef::Knife::CookbookUpload do |config|
        config[:cookbook_path] = "#{repo_path}/cookbooks"
        config[:all] = true
      end
    end.to_not raise_error
    expect(Chef::CookbookVersion.list.keys).to include('apt')
  end
  it '#show' do
    expect do
      knife Chef::Knife::CookbookShow, 'apt'
    end.to_not raise_error
  end
  it '#delete' do
    expect do
      knife Chef::Knife::CookbookDelete, 'apt' do |config|
        config[:yes] = true
      end
    end.to_not raise_error
    expect(Chef::CookbookVersion.list.keys).to_not include('apt')
  end
end
