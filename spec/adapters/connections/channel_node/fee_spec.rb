# frozen_string_literal: true

require_relative '../../../../adapters/connections/channel_node/fee'
require_relative '../../../../ports/grpc'

RSpec.describe Lighstorm::Adapter::Fee do
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
        { _source: :fee_report,
          id: '848916435345801217',
          partner: {
            policy: {
              fee: {
                base: { milisatoshis: 0 },
                rate: { parts_per_million: 874 }
              }
            }
          } }
      )
    end
  end
end
