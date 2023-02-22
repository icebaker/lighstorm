# frozen_string_literal: true

require_relative '../../models/rate'

RSpec.describe Lighstorm::Models::Rate do
  describe 'rate' do
    it 'creates' do
      rate = described_class.new(parts_per_million: 50)

      expect(rate.parts_per_million).to eq(50)
      expect(rate.ppm).to eq(50)
      expect(rate.percentage).to eq(0.005)
      expect(rate.to_h).to eq({ parts_per_million: 50 })
    end
  end
end
