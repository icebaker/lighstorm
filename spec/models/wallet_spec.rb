# frozen_string_literal: true

require 'json'

require_relative '../../controllers/wallet'
require_relative '../../controllers/wallet/balance'

require_relative '../../models/wallet'

require_relative '../../ports/dsl/lighstorm/errors'

RSpec.describe Lighstorm::Models::Wallet do
  describe '.balance' do
    it 'models' do
      data = Lighstorm::Controllers::Wallet::Balance.data(
        Lighstorm::Controllers::Wallet.components
      ) do |fetch|
        VCR.tape.replay('Controllers::Wallet.balance') { fetch.call }
      end

      balance = described_class.new(data)

      expect(balance._key.size).to eq(64)
      expect(balance.at.utc.to_s).to eq('2023-03-20 23:27:54 UTC')
      expect(balance.lightning.millisatoshis).to eq(6_403_153_467)
      expect(balance.bitcoin.millisatoshis).to eq(249_765_000)
      expect(balance.total.millisatoshis).to eq(6_652_918_467)

      Contract.expect(
        balance.to_h, '440dbbe22d4b8abfba41a6a182e4d54306800289018bddf73eeed8f22f7350af'
      ) do |actual, expected|
        expect(actual.hash).to eq(expected.hash)
        expect(actual.contract).to eq(expected.contract)
      end
    end
  end
end
