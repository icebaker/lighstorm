# frozen_string_literal: true

require 'json'

require_relative '../../adapters/wallet'
require_relative '../../ports/grpc'

RSpec.describe Lighstorm::Adapter::Wallet do
  context 'balance' do
    it 'adapts' do
      raw = VCR.tape.replay('lightning.wallet_balance.channel_balance') do
        {
          at: Time.now,
          wallet_balance: Lighstorm::Ports::GRPC.lightning.wallet_balance.to_h,
          channel_balance: Lighstorm::Ports::GRPC.lightning.channel_balance.to_h
        }
      end

      Contract.expect(
        raw,
        '50360c135e430b161a579b3705919ff456ebaa511f2793cc5fabff6075db92e6'
      ) do |actual, expected|
        expect(actual.hash).to eq(expected.hash)
        expect(actual.contract).to eq(expected.contract)
      end

      adapted = described_class.balance(raw)

      Contract.expect(
        adapted,
        '440dbbe22d4b8abfba41a6a182e4d54306800289018bddf73eeed8f22f7350af'
      ) do |actual, expected|
        expect(actual.hash).to eq(expected.hash)
        expect(actual.contract).to eq(expected.contract)

        expect(actual.contract).to eq(
          { _key: 'String:50+',
            at: 'Time',
            bitcoin: { millisatoshis: 'Integer:0..10' },
            lightning: { millisatoshis: 'Integer:0..10' },
            total: { millisatoshis: 'Integer:0..10' } }
        )
      end
    end
  end
end
