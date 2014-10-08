require 'spec_helper'
require 'chef/knife/client_create'
require 'chef/knife/client_show'
require 'chef/knife/client_delete'

describe 'APIClient' do
  it '#create' do
    expect do
      knife Chef::Knife::ClientCreate, 'bar' do |config|
        config[:disable_editing] = true
        config[:admin] = true
      end
    end.to_not raise_error
    expect(Chef::ApiClient.load('bar').name).to eq('bar')
  end
  it '#show' do
    expect do
      knife Chef::Knife::ClientShow, 'bar'
    end.to_not raise_error
  end
  it '#delete' do
    expect do
      knife Chef::Knife::ClientDelete, 'bar' do |config|
        config[:yes] = true
      end
    end.to_not raise_error
    expect(Chef::ApiClient.list.keys).to_not include('bar')
  end
end
