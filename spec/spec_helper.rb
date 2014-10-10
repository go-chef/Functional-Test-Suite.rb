require 'rspec'
require_relative '../lib/provisioner'

RSpec.configure do |config|
  config.fail_fast = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  config.include Provisioner
  config.before(:suite) do
    Provisioner.create_goiardi
    Provisioner.create_server('node1')
  end
  config.after(:suite) do
    Provisioner.delete_server('goiardi')
    Provisioner.delete_server('node1')
  end
  config.backtrace_exclusion_patterns = []
end
