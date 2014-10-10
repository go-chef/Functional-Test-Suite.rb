require 'spec_helper'
require 'chef/knife/data_bag_create'
require 'chef/knife/data_bag_show'
require 'chef/knife/data_bag_delete'

describe 'DataBag' do
  it '#create' do
    expect do
      knife Chef::Knife::DataBagCreate, 'test-dbag' do |config|
        config[:disable_editing] = true
      end
    end.to_not raise_error
  end
  it '#show' do
    expect do
      knife Chef::Knife::DataBagShow, 'test-dbag'
    end.to_not raise_error
  end
  it '#delete' do
    expect do
      knife Chef::Knife::DataBagDelete, 'test-dbag' do |config|
        config[:yes] = true
      end
    end.to_not raise_error
  end
end
