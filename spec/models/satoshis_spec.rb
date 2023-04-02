# frozen_string_literal: true

require_relative '../../models/satoshis'

RSpec.describe Lighstorm::Model::Satoshis do
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

  describe 'bitcoins' do
    it 'creates 0.0045' do
      amount = described_class.new(
        bitcoins: 0.0049
      )

      expect(amount.bitcoins).to eq(0.0049)
      expect(amount.millisatoshis).to eq(490_000_000)
      expect(amount.satoshis).to eq(490_000)

      expect(amount.msats).to eq(490_000_000)
      expect(amount.sats).to eq(490_000.0)
      expect(amount.btc).to eq(0.0049)

      expect(amount.parts_per_million(25_000_000_000_000)).to eq(19.599999999999998)

      expect(amount.to_h).to eq({ millisatoshis: 490_000_000 })
    end

    it 'creates 1' do
      amount = described_class.new(
        bitcoins: 1
      )

      expect(amount.satoshis).to eq(100_000_000)
      expect(amount.bitcoins).to eq(1)
      expect(amount.millisatoshis).to eq(100_000_000_000)

      expect(amount.msats).to eq(100_000_000_000)
      expect(amount.sats).to eq(100_000_000.0)
      expect(amount.btc).to eq(1.0)

      expect(amount.parts_per_million(25_000_000_000_000)).to eq(4000.0)

      expect(amount.to_h).to eq({ millisatoshis: 100_000_000_000 })
    end
  end
end
