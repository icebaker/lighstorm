# frozen_string_literal: true

require_relative '../../../../adapters/lightning/edges/forward'
require_relative '../../../../ports/grpc'

RSpec.describe Lighstorm::Adapter::Lightning::Forward do
  context 'forwarding_history' do
    it 'adapts' do
      raw = VCR.tape.replay('lightning.forwarding_history.first') do
        Lighstorm::Ports::GRPC.lightning.forwarding_history.forwarding_events.first.to_h
      end

      Contract.expect(
        raw,
        'a8e0c47d3a18eba567788d9e4d2c379a3fba98d5d300bd1b8fe5ce68c479a139'
      ) do |actual, expected|
        expect(actual.hash).to eq(expected.hash)
        expect(actual.contract).to eq(expected.contract)
      end

      adapted = described_class.forwarding_history(raw)

      expect(adapted[:at]).to be_a(Time)

      adapted[:at] = adapted[:at].utc.to_s

      expect(adapted).to eq(
        { _source: :forwarding_history,
          _key: '9cdae1a0727397e187eae315e49d9254ffa6a4aac60be5575b16eecb47a019ff',
          at: '2023-01-16 14:49:43 UTC',
          fee: { millisatoshis: 5206 },
          in: {
            amount: { millisatoshis: 69_428_816 },
            channel: { id: '848952719119024129' }
          },
          out: {
            amount: { millisatoshis: 69_423_610 },
            channel: { id: '848952719173877762' }
          } }
      )
    end
  end
end
