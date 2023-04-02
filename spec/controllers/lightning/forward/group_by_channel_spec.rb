# frozen_string_literal: true

require 'json'

# Circular dependency issue:
# https://stackoverflow.com/questions/8057625/ruby-how-to-require-correctly-to-avoid-circular-dependencies
require_relative '../../../../models/lightning/edges/channel/hop'
require_relative '../../../../controllers/lightning/forward'
require_relative '../../../../controllers/lightning/forward/group_by_channel'

RSpec.describe Lighstorm::Controller::Lightning::Forward::GroupByChannel do
  describe 'limit' do
    it 'limits' do
      data = described_class.data(
        Lighstorm::Controller::Lightning::Forward.components,
        limit: 1
      ) do |fetch|
        VCR.tape.replay('Controller::Lightning::Forward.group_by_channel', limit: 1) { fetch.call }
      end

      expect(data.size).to eq(1)

      data = described_class.data(
        Lighstorm::Controller::Lightning::Forward.components,
        limit: 2
      ) do |fetch|
        VCR.tape.replay('Controller::Lightning::Forward.group_by_channel', limit: 2) { fetch.call }
      end

      expect(data.size).to eq(2)

      Contract.expect(
        data.first, '5e1759a0f43ec8958f68f4c39abb4e1a11dbbde8a172b3a35e5e8a6e7337c112'
      ) do |actual, expected|
        expect(actual.hash).to eq(expected.hash)
        expect(actual.contract).to eq(expected.contract)
      end
    end
  end
end
