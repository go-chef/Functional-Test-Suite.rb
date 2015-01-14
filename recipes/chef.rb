
execute 'apt-get update -y'
package 'openssh-server'

execute 'echo ubuntu:ubuntu | chpasswd'

remote_file '/tmp/chef.deb' do
  source 'https://opscode-omnibus-packages.s3.amazonaws.com/ubuntu/13.04/x86_64/chef_12.0.3-1_amd64.deb'
  mode 0644
  action :create_if_missing
end

dpkg_package 'chef' do
  source '/tmp/chef.deb'
  action :install
end
