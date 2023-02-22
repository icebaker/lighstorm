# frozen_string_literal: true

require_relative '../../adapters/invoice'
require_relative '../../ports/grpc'

RSpec.describe Lighstorm::Adapter::Invoice do
  context 'list_invoices' do
    it 'adapts' do
      raw = VCR.replay('lightning.list_invoices.first/memo/settled') do
        Lighstorm::Ports::GRPC.lightning.list_invoices.invoices.find do |invoice|
          invoice.memo != '' && invoice.state == :SETTLED
        end.to_h
      end

      Contract.expect(
        raw, '77b0c3a51abe67133e981bc362430b2600d23200e9b3b335c890a975bda44575'
      ) do |actual, expected|
        expect(actual.hash).to eq(expected.hash)
        expect(actual.contract).to eq(expected.contract)
      end

      adapted = described_class.list_invoices(raw)

      Contract.expect(
        adapted, '626f7aebf929043b3c6d372da5c630c161aed1b5fcd93f7f14a1e6b7e22d2f3e'
      ) do |actual, expected|
        expect(actual.hash).to eq(expected.hash)
        expect(actual.contract).to eq(expected.contract)

        expect(actual.contract).to eq(
          { _key: 'String:50+',
            _source: 'Symbol:11..20',
            created_at: 'DateTime',
            request: {
              _source: 'Symbol:11..20',
              address: 'String:50+',
              amount: { milisatoshis: 'Integer:0..10' },
              code: 'String:50+',
              description: { hash: 'Nil', memo: 'String:21..30' },
              secret: { hash: 'String:50+', preimage: 'String:50+' }
            },
            settle_at: 'DateTime',
            state: 'String:0..10' }
        )
      end
    end
  end

  context 'lookup_invoice' do
    it 'adapts' do
      secret_hash = '7dc0a651f241c5c940ae303338e96af942b7559009728e2ab046d8f6583419ba'

      raw = VCR.replay("lightning.lookup_invoice/#{secret_hash}") do
        Lighstorm::Ports::GRPC.lightning.lookup_invoice(
          r_hash_str: secret_hash
        ).to_h
      end

      Contract.expect(
        raw, '77b0c3a51abe67133e981bc362430b2600d23200e9b3b335c890a975bda44575'
      ) do |actual, expected|
        expect(actual.hash).to eq(expected.hash)
        expect(actual.contract).to eq(expected.contract)
      end

      adapted = described_class.lookup_invoice(raw)

      Contract.expect(
        adapted, '626f7aebf929043b3c6d372da5c630c161aed1b5fcd93f7f14a1e6b7e22d2f3e'
      ) do |actual, expected|
        expect(actual.hash).to eq(expected.hash)
        expect(actual.contract).to eq(expected.contract)

        expect(actual.contract).to eq(
          { _key: 'String:50+',
            _source: 'Symbol:11..20',
            created_at: 'DateTime',
            request: {
              _source: 'Symbol:11..20',
              address: 'String:50+',
              amount: { milisatoshis: 'Integer:0..10' },
              code: 'String:50+',
              description: { hash: 'Nil', memo: 'String:21..30' },
              secret: { hash: 'String:50+', preimage: 'String:50+' }
            },
            settle_at: 'DateTime',
            state: 'String:0..10' }
        )
      end
    end
  end
end
