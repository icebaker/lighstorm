# frozen_string_literal: true

require_relative '../../../adapters/edges/payment'
require_relative '../../../ports/grpc'

RSpec.describe Lighstorm::Adapter::Payment do
  context 'list_payments' do
    it 'adapts' do
      raw = VCR.tape.replay('lightning.list_payments.first') do
        Lighstorm::Ports::GRPC.lightning.list_payments.payments.first.to_h
      end

      Contract.expect(
        raw,
        '48c76f599881ae457efe6ab3e43382f993159ca68c55f05da70e4b7537d2608f'
      ) do |actual, expected|
        expect(actual.hash).to eq(expected.hash)
        expect(actual.contract).to eq(expected.contract)
      end

      node_get_info = VCR.tape.replay('lightning.get_info') do
        Lighstorm::Ports::GRPC.lightning.get_info.to_h
      end

      adapted = described_class.list_payments(raw, node_get_info)

      Contract.expect(
        adapted, '434176033c4a8b661deb125b86db0de6906230d8caba04ec460d509402b76342'
      ) do |actual, expected|
        expect(actual.hash).to eq(expected.hash)
        expect(actual.contract).to eq(expected.contract)

        expect(actual.contract).to eq(
          { _key: 'String:50+',
            _source: 'Symbol:11..20',
            created_at: 'Time',
            fee: { millisatoshis: 'Integer:0..10' },
            hops: [
              { _source: 'Symbol:11..20',
                amount: { millisatoshis: 'Integer:0..10' },
                channel: {
                  _key: 'String:50+',
                  id: 'String:11..20',
                  partners: [{ node: { _key: 'String:50+', public_key: 'String:50+' } }],
                  target: { public_key: 'String:50+' }
                },
                fee: { millisatoshis: 'Integer:0..10' },
                hop: 'Integer:0..10' },
              { _source: 'Symbol:11..20',
                amount: { millisatoshis: 'Integer:0..10' },
                channel: {
                  _key: 'String:50+',
                  id: 'String:11..20',
                  partners: [{ node: { _key: 'String:50+', public_key: 'String:50+' } }],
                  target: { public_key: 'String:50+' }
                },
                fee: { millisatoshis: 'Integer:0..10' },
                hop: 'Integer:0..10' }
            ],
            purpose: 'String:0..10',
            request: {
              _source: 'Symbol:11..20',
              address: 'String:50+',
              amount: { millisatoshis: 'Integer:0..10' },
              code: 'String:50+',
              secret: { hash: 'String:50+', preimage: 'String:50+' }
            },
            settled_at: 'Time',
            status: 'String:0..10' }
        )
      end
    end
  end

  context 'list_payments unexpected' do
    it 'raises error' do
      expect { described_class.list_payments({ htlcs: %w[a b] }, nil) }.to raise_error(
        UnexpectedNumberOfHTLCsError, 'htlcs: 2'
      )
    end
  end
end
