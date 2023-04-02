# frozen_string_literal: true

require 'json'

require_relative '../../controllers/wallet'
require_relative '../../controllers/wallet/balance'

RSpec.describe Lighstorm::Model::Wallet::Balance do
  describe '.balance' do
    it 'models' do
      data = Lighstorm::Controller::Wallet::Balance.data(
        Lighstorm::Controller::Wallet.components
      ) do |fetch|
        VCR.tape.replay('Controller::Wallet.balance') { fetch.call }
      end

      balance = described_class.new(data)

      expect(balance._key.size).to eq(64)
      expect(balance.at.utc.to_s).to eq('2023-04-02 13:13:04 UTC')
      expect(balance.lightning.millisatoshis).to eq(25_021_150)
      expect(balance.bitcoin.millisatoshis).to eq(3_497_221_000)
      expect(balance.total.millisatoshis).to eq(3_522_242_150)

      Contract.expect(
        balance.to_h, '440dbbe22d4b8abfba41a6a182e4d54306800289018bddf73eeed8f22f7350af'
      ) do |actual, expected|
        expect(actual.hash).to eq(expected.hash)
        expect(actual.contract).to eq(expected.contract)
      end
    end
  end
end
