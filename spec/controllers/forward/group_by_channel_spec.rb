# frozen_string_literal: true

require 'json'

# Circular dependency issue:
# https://stackoverflow.com/questions/8057625/ruby-how-to-require-correctly-to-avoid-circular-dependencies
require_relative '../../../models/edges/channel/hop'
require_relative '../../../controllers/forward'
require_relative '../../../controllers/forward/group_by_channel'

RSpec.describe Lighstorm::Controllers::Forward::GroupByChannel do
  describe 'limit' do
    it 'limits' do
      data = described_class.data(
        Lighstorm::Controllers::Forward.components,
        limit: 1
      ) do |fetch|
        VCR.tape.replay('Controllers::Forward.group_by_channel', limit: 1) { fetch.call }
      end

      expect(data.size).to eq(1)

      data = described_class.data(
        Lighstorm::Controllers::Forward.components,
        limit: 2
      ) do |fetch|
        VCR.tape.replay('Controllers::Forward.group_by_channel', limit: 2) { fetch.call }
      end

      expect(data.size).to eq(2)
    end
  end
end
