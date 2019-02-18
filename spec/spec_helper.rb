require 'simplecov'
require 'rspec'

# Start Simplecov
SimpleCov.start do
  add_filter 'spec/'
end

# Configure RSpec
RSpec.configure do |config|
  config.color = true
  config.fail_fast = false

  config.order = :random
  Kernel.srand config.seed

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

def get_fixture_path(name)
  File.expand_path("fixtures/#{name}", __dir__)
end

require 'active_settings'
