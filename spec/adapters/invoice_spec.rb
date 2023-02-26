# frozen_string_literal: true

require_relative '../../adapters/invoice'
require_relative '../../ports/grpc'

RSpec.describe Lighstorm::Adapter::Invoice do
  context 'list_invoices' do
    it 'adapts' do
      raw = VCR.tape.replay('lightning.list_invoices.first/memo/settled') do
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
        adapted, '896e46ed54278c8d5c0ccab4f551665c2253aa4494ca9122555d9b082d4f65e1'
      ) do |actual, expected|
        expect(actual.hash).to eq(expected.hash)
        expect(actual.contract).to eq(expected.contract)

        expect(actual.contract).to eq(
          { _key: 'String:50+',
            _source: 'Symbol:11..20',
            created_at: 'Time',
            request: {
              _source: 'Symbol:11..20',
              address: 'String:50+',
              amount: { milisatoshis: 'Integer:0..10' },
              code: 'String:50+',
              description: { hash: 'Nil', memo: 'String:21..30' },
              secret: { hash: 'String:50+', preimage: 'String:50+' }
            },
            settle_at: 'Time',
            state: 'String:0..10' }
        )
      end
    end
  end

  context 'lookup_invoice' do
    context 'settled' do
      it 'adapts' do
        secret_hash = '7dc0a651f241c5c940ae303338e96af942b7559009728e2ab046d8f6583419ba'

        raw = VCR.tape.replay("lightning.lookup_invoice/#{secret_hash}") do
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
          adapted, '896e46ed54278c8d5c0ccab4f551665c2253aa4494ca9122555d9b082d4f65e1'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)

          expect(actual.contract).to eq(
            { _key: 'String:50+',
              _source: 'Symbol:11..20',
              created_at: 'Time',
              request: {
                _source: 'Symbol:11..20',
                address: 'String:50+',
                amount: { milisatoshis: 'Integer:0..10' },
                code: 'String:50+',
                description: { hash: 'Nil', memo: 'String:21..30' },
                secret: { hash: 'String:50+', preimage: 'String:50+' }
              },
              settle_at: 'Time',
              state: 'String:0..10' }
          )
        end
      end
    end

    context 'open' do
      it 'adapts' do
        secret_hash = '3055894c40aac008121ad045475a3b124f7214e5e08ec42902a63ef28f59e4fc'

        raw = VCR.tape.replay("lightning.lookup_invoice/#{secret_hash}") do
          Lighstorm::Ports::GRPC.lightning.lookup_invoice(
            r_hash_str: secret_hash
          ).to_h
        end

        Contract.expect(
          raw, '780ce5a83b1ab5ced0a97ab1a565c2bb4af70e8d8eb155d3c2f5575d49468669'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)
        end

        adapted = described_class.lookup_invoice(raw)

        Contract.expect(
          adapted, 'f48a4d13cece109155f98e062a29dc7ac6719bb8291b05de69007fff8b2401dc'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)

          expect(actual.contract).to eq(
            { _key: 'String:50+',
              _source: 'Symbol:11..20',
              created_at: 'Time',
              request: {
                _source: 'Symbol:11..20',
                address: 'String:50+',
                amount: { milisatoshis: 'Integer:0..10' },
                code: 'String:50+',
                description: { hash: 'Nil', memo: 'String:0..10' },
                secret: { hash: 'String:50+', preimage: 'String:50+' }
              },
              settle_at: 'Nil',
              state: 'String:0..10' }
          )
        end
      end
    end
  end
end
