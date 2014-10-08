require 'rspec'
require_relative 'machine'

RSpec.configure do |config|
  config.fail_fast = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  config.include Helper
  config.before(:suite) do
    Helper.install_server
  end
  config.after(:suite) do
    Helper.uninstall_server
  end
  config.backtrace_exclusion_patterns = []
end
