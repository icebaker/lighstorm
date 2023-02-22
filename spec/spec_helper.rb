# frozen_string_literal: true

require 'dotenv/load'

require_relative './helpers/vcr'
require_relative './helpers/contract'
require_relative './helpers/sanitizer'

def check_integration!(slow: false)
  if ENV.fetch('LIGHSTORM_RUN_INTEGRATION_TESTS') != 'true'
    skip('integration tests are disabled')
    return
  end

  return unless slow && ENV.fetch('LIGHSTORM_RUN_INTEGRATION_TESTS_SLOW') != 'true'

  skip('slow integration tests are disabled')
end

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
end
