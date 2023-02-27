# frozen_string_literal: true

require_relative '../../adapters/payment_request'
require_relative '../../ports/grpc'

RSpec.describe Lighstorm::Adapter::PaymentRequest do
  context 'decode_pay_req' do
    it 'adapts' do
      payment_code = 'lnbc10n1p374jnvpp5qrdyr668cmh7ftnmv299nfxp4sle44dam9538r9agvyqggez9gusdqs2d68ycthvfjhyunecqzpgxqyz5vqsp5492cchna2qnqlf26azlljwatuxqcck7epagtx55lvgk9uw7gn4aq9qyyssqt5xs2rhg7z4x7pj2crazw5yfesugwzf03eylvsjgumfwvufp3vzq0lk98t5lm7np9x9465p7el07q07sl8nyyxnlc767mlanr8nvuzqpp3d65y'

      raw = VCR.tape.replay("lightning.decode_pay_req/#{payment_code}") do
        Lighstorm::Ports::GRPC.lightning.decode_pay_req(
          pay_req: payment_code
        ).to_h
      end

      Contract.expect(
        raw, 'd55fb253f865f7080aebe148970d9d0a53c34aea42bcefe416231344b5f75d2c'
      ) do |actual, expected|
        expect(actual.hash).to eq(expected.hash)
        expect(actual.contract).to eq(expected.contract)
      end

      adapted = described_class.decode_pay_req(raw)

      Contract.expect(
        adapted, '1d5ac1a2a1c6d4ef78491712e0752fa3020c962952e993029ba2c05f2d1f03cd'
      ) do |actual, expected|
        expect(actual.hash).to eq(expected.hash)
        expect(actual.contract).to eq(expected.contract)
        expect(actual.data[:_source]).to eq(:decode_pay_req)

        expect(actual.contract).to eq(
          { _source: 'Symbol:11..20',
            address: 'String:50+',
            amount: { milisatoshis: 'Integer:0..10' },
            description: { hash: 'Nil', memo: 'String:0..10' },
            secret: { hash: 'String:50+' } }
        )
      end
    end
  end

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
        adapted, '8cf07999dfc949076f097a93f9edfe2e3a703be02b89f9df0988c4ec8fab76c4'
      ) do |actual, expected|
        expect(actual.hash).to eq(expected.hash)
        expect(actual.contract).to eq(expected.contract)
        expect(actual.data[:_source]).to eq(:list_invoices)

        expect(actual.contract).to eq(
          { _source: 'Symbol:11..20',
            address: 'String:50+',
            amount: { milisatoshis: 'Integer:0..10' },
            code: 'String:50+',
            description: { hash: 'Nil', memo: 'String:21..30' },
            secret: { hash: 'String:50+', preimage: 'String:50+' } }
        )
      end
    end
  end

  context 'lookup_invoice' do
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
        adapted, '8cf07999dfc949076f097a93f9edfe2e3a703be02b89f9df0988c4ec8fab76c4'
      ) do |actual, expected|
        expect(actual.hash).to eq(expected.hash)
        expect(actual.contract).to eq(expected.contract)
        expect(actual.data[:_source]).to eq(:lookup_invoice)

        expect(actual.contract).to eq(
          { _source: 'Symbol:11..20',
            address: 'String:50+',
            amount: { milisatoshis: 'Integer:0..10' },
            code: 'String:50+',
            description: { hash: 'Nil', memo: 'String:21..30' },
            secret: { hash: 'String:50+', preimage: 'String:50+' } }
        )
      end
    end
  end

  context 'list_payments unexpected' do
    it 'raises error' do
      expect { described_class.list_payments({ htlcs: %w[a b] }) }.to raise_error(
        UnexpectedNumberOfHTLCsError, 'htlcs: 2'
      )
    end
  end

  context 'list_payments' do
    it 'adapts' do
      raw = VCR.tape.replay('lightning.list_payments.first') do
        Lighstorm::Ports::GRPC.lightning.list_payments.payments.first.to_h
      end

      Contract.expect(
        raw, '48c76f599881ae457efe6ab3e43382f993159ca68c55f05da70e4b7537d2608f'
      ) do |actual, expected|
        expect(actual.hash).to eq(expected.hash)
        expect(actual.contract).to eq(expected.contract)
      end

      adapted = described_class.list_payments(raw)

      Contract.expect(
        adapted, 'd6724b0b9f8385c31b98decbac7ea44034c40db9ca8d6dc95a5967f3d4c8751f'
      ) do |actual, expected|
        expect(actual.hash).to eq(expected.hash)
        expect(actual.contract).to eq(expected.contract)
        expect(actual.data[:_source]).to eq(:list_payments)

        expect(actual.contract).to eq(
          { _source: 'Symbol:11..20',
            address: 'String:50+',
            amount: { milisatoshis: 'Integer:0..10' },
            code: 'String:50+',
            secret: { hash: 'String:50+', preimage: 'String:50+' } }
        )
      end
    end
  end
end
