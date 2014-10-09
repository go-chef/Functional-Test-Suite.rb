require 'rspec'
require_relative '../lib/provisioner'

RSpec.configure do |config|
  config.fail_fast = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  config.include Provisioner
  config.before(:suite) do
    Provisioner.create_server('goiardi')
  end
  config.after(:suite) do
    Provisioner.delete_server('goiardi')
  end
  config.backtrace_exclusion_patterns = []
end
