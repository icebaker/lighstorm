# frozen_string_literal: true

require 'rainbow'

require 'dotenv/load'

require_relative './helpers/vcr'
require_relative './helpers/contract'
require_relative './helpers/sanitizer'
require_relative './helpers/test_data'

def check_integration!(slow: false)
  if ENV.fetch('LIGHSTORM_RUN_INTEGRATION_TESTS', 'false') != 'true'
    skip('integration tests are inactive')
    return
  end

  return unless slow && ENV.fetch('LIGHSTORM_RUN_INTEGRATION_TESTS_SLOW', 'false') != 'true'

  skip('slow integration tests are inactive')
end

def symbolize_keys(object)
  case object
  when Hash
    object.each_with_object({}) do |(key, value), result|
      result[key.to_sym] = symbolize_keys(value)
    end
  when Array
    object.map { |e| symbolize_keys(e) }
  else
    object
  end
end

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  config.before(:suite) do
    Contract::Monitor.instance.reboot!
    VCR::Monitor.instance.reboot!
    TestData::Monitor.instance.reboot!
  end

  config.after(:suite) do
    if ARGV.count == 0 && RSpec.world.filtered_examples.values.flatten.none?(&:exception)
      accessed_files = Contract::Monitor.instance.accessed_files.merge(
        VCR::Monitor.instance.accessed_files
      ).merge(
        TestData::Monitor.instance.accessed_files
      )

      unused_files = []

      Dir.glob('spec/data/**/*').each do |file|
        next unless File.file?(file)
        next if accessed_files[file]

        unused_files << file
      end

      unless unused_files.empty?
        print Rainbow("\n\nWarning: #{unused_files.size} unused test data files were found.").magenta

        if $stdout.tty? && !unused_files.empty? &&
           ENV.fetch('LIGHSTORM_DELETE_UNUSED_TEST_DATA', 'false') == 'true'

          puts "\nDeleting unused files..."
          unused_files.each do |path|
            File.delete(path)
            puts " - #{Rainbow(path).red}"
          end

          print "\n#{unused_files.size} unused test data files deleted!"
        else
          unused_files.each do |path|
            puts " - #{Rainbow(path).yellow}"
          end
        end
      end
    end
  end
end
