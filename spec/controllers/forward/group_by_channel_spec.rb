# frozen_string_literal: true

require 'json'

require_relative '../../../controllers/forward/group_by_channel'

RSpec.describe Lighstorm::Controllers::Forward::GroupByChannel do
  describe 'limit' do
    it 'limits' do
      data = described_class.data(limit: 1) do |fetch|
        VCR.replay('Controllers::Forward.group_by_channel', { limit: 1 }) { fetch.call }
      end

      expect(data.size).to eq(1)

      data = described_class.data(limit: 2) do |fetch|
        VCR.replay('Controllers::Forward.group_by_channel', { limit: 2 }) { fetch.call }
      end

      expect(data.size).to eq(2)
    end
  end
end
