# frozen_string_literal: true

require_relative '../../../adapters/edges/payment'
require_relative '../../../ports/grpc'

RSpec.describe Lighstorm::Adapter::Payment do
  context 'spontaneous' do
    context 'amp' do
      it 'adapts' do
        raw = VCR.reel.replay('lightning.list_payments/amp') do
          Lighstorm::Ports::GRPC.lightning.list_payments.payments.find do |payment|
            payment.payment_hash == '6105ed805c830aa35cc0a8a5de5f25436aa2fb89eb42d9cdfedcb62375fc4dea'
          end.to_h
        end

        Contract.expect(
          raw,
          '6e99918b861c2778dc6cbf6638f14cb89602733faead6d4cd08686cca1348b04'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)
        end

        node_get_info = VCR.tape.replay('lightning.get_info') do
          Lighstorm::Ports::GRPC.lightning.get_info.to_h
        end

        adapted = described_class.list_payments(raw, node_get_info)

        expect(adapted[:amount][:millisatoshis]).to eq(3000)
        expect(adapted[:through]).to eq('amp')
      end
    end

    context 'keysend' do
      it 'adapts' do
        raw = VCR.reel.replay('lightning.list_payments/keysend') do
          Lighstorm::Ports::GRPC.lightning.list_payments.payments.find do |payment|
            payment.payment_hash == '832446c79a2cf26dd927f9f48c92b8336431a4bef355db7394237dce7337aa69'
          end.to_h
        end

        node_get_info = VCR.tape.replay('lightning.get_info') do
          Lighstorm::Ports::GRPC.lightning.get_info.to_h
        end

        Contract.expect(
          raw,
          '15a1f7d9b05754994e58f8c6ea82b114587fc6a57f524568e411dfd901df4912'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)
        end

        adapted = described_class.list_payments(raw, node_get_info)

        expect(adapted[:amount][:millisatoshis]).to eq(2000)
        expect(adapted[:through]).to eq('keysend')
      end
    end
  end

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
        adapted, '1cbdc0c54ef8ad5c06c386be3305af21d1fdd1c39e3eab11428c7aaadc06fb3c'
      ) do |actual, expected|
        expect(actual.hash).to eq(expected.hash)
        expect(actual.contract).to eq(expected.contract)

        expect(actual.contract).to eq(
          { _key: 'String:50+',
            _source: 'Symbol:11..20',
            amount: { millisatoshis: 'Integer:0..10' },
            at: 'Time',
            fee: { millisatoshis: 'Integer:0..10' },
            hops: [{ _source: 'Symbol:11..20',
                     amount: { millisatoshis: 'Integer:0..10' },
                     channel: { _key: 'String:50+',
                                id: 'String:11..20',
                                partners: [{ node: { _key: 'String:50+', public_key: 'String:50+' } }],
                                target: { public_key: 'String:50+' } },
                     fee: { millisatoshis: 'Integer:0..10' },
                     hop: 'Integer:0..10' },
                   { _source: 'Symbol:11..20',
                     amount: { millisatoshis: 'Integer:0..10' },
                     channel: { _key: 'String:50+',
                                id: 'String:11..20',
                                partners: [{ node: { _key: 'String:50+', public_key: 'String:50+' } }],
                                target: { public_key: 'String:50+' } },
                     fee: { millisatoshis: 'Integer:0..10' },
                     hop: 'Integer:0..10' }],
            invoice: { _key: 'String:50+',
                       _source: 'Symbol:11..20',
                       amount: { millisatoshis: 'Integer:0..10' },
                       code: 'String:50+',
                       created_at: 'Time',
                       description: { hash: 'Nil', memo: 'Nil' },
                       payable: 'String:0..10',
                       secret: { hash: 'String:50+', preimage: 'String:50+' },
                       settled_at: 'Time',
                       state: 'Nil' },
            purpose: 'String:0..10',
            secret: { hash: 'String:50+', preimage: 'String:50+' },
            state: 'String:0..10',
            through: 'String:0..10' }
        )
      end
    end
  end
end
