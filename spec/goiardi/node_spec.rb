require 'spec_helper'
require 'chef/knife/node_create'
require 'chef/knife/node_show'
require 'chef/knife/node_delete'

describe 'Node' do
  it '#create' do
    expect do
      knife Chef::Knife::NodeCreate, 'foo' do |config|
        config[:disable_editing] = true
      end
    end.to_not raise_error
    expect(Chef::Node.load('foo').name).to eq('foo')
  end
  it '#show' do
    expect do
      knife Chef::Knife::NodeShow, 'foo'
    end.to_not raise_error
  end
  it '#delete' do
    expect do
      knife Chef::Knife::NodeDelete, 'foo' do |config|
        config[:yes] = true
      end
    end.to_not raise_error
    expect(Chef::Node.list.keys).to_not include('foo')
  end
end
