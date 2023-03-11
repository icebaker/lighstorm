# frozen_string_literal: true

RSpec.describe VCR do
  FILE_READ_ALLOWED = [
    'spec/helpers/contract.rb',
    'spec/helpers/tasks/contracts.rb',
    'spec/helpers/test_data.rb',
    'spec/helpers/test_data_spec.rb',
    'spec/helpers/vcr.rb',
    'spec/helpers/vcr_spec.rb'
  ].freeze

  describe 'ensure no File.read' do
    it 'ensures no File.read' do
      Dir.glob('spec/**/*.rb').each do |file|
        content = File.read(file)
        if content =~ (/File\.read/) && !FILE_READ_ALLOWED.include?(file)
          expect { raise "File.read not allowed, but found at '#{file}'" }.not_to raise_error
        end
      end
    end
  end
end
