require 'rspec'
require 'lxc'
require 'lxc/extra'

module Helper
  def start_goiardi
    ct_name = ENV['GOIARDI_CONTAINER'] || 'goiardi'
    ct = LXC::Container.new(ct_name)
    unless ct.defined?
      ct.create('download', nil, {}, 0, %w{-a amd64 -r trusty -d ubuntu})
    end
    unless ct.running?
      ct.start
      sleep 1 while ct.ip_addresses.empty?
    end
    
  end
end

RSpec.configure do |config|
  config.fail_fast = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  config.include Helper
  config.backtrace_exclusion_patterns = []
end
