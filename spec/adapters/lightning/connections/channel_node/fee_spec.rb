# frozen_string_literal: true

require_relative '../../../../../adapters/lightning/connections/channel_node/fee'
require_relative '../../../../../ports/grpc'

RSpec.describe Lighstorm::Adapter::Lightning::Fee do
  context 'list_channels' do
    it 'adapts' do
      raw = VCR.tape.replay('lightning.fee_report.channel_fees.first') do
        Lighstorm::Ports::GRPC.lightning.fee_report.channel_fees.first.to_h
      end

      Contract.expect(
        raw,
        '1570b256c59d681913a330671071b11bd72553c5910ea690604ea0cf9a644a7b'
      ) do |actual, expected|
        expect(actual.hash).to eq(expected.hash)
        expect(actual.contract).to eq(expected.contract)
      end

      adapted = described_class.fee_report(raw)

      expect(adapted).to eq(
        {
          _source: :fee_report,
          id: '118747255865345',
          partner: {
            policy: {
              fee: {
                base: { millisatoshis: 1000 },
                rate: { parts_per_million: 1 }
              }
            }
          }
        }
      )
    end
  end
end
