# frozen_string_literal: true

require_relative '../../models/satoshis'

RSpec.describe Lighstorm::Models::Satoshis do
  describe 'satoshis' do
    it 'creates' do
      amount = described_class.new(
        millisatoshis: 50_000_000_000
      )

      expect(amount.millisatoshis).to eq(50_000_000_000)
      expect(amount.satoshis).to eq(50_000_000)
      expect(amount.bitcoins).to eq(0.5)

      expect(amount.msats).to eq(50_000_000_000)
      expect(amount.sats).to eq(50_000_000)
      expect(amount.btc).to eq(0.5)

      expect(amount.parts_per_million(25_000_000_000_000)).to eq(2000)

      expect(amount.to_h).to eq({ millisatoshis: 50_000_000_000 })
    end
  end
end
