# frozen_string_literal: true

require_relative '../../adapters/invoice'
require_relative '../../ports/grpc'

RSpec.describe Lighstorm::Adapter::Invoice do
  let(:at) { Time.new(2023, 3, 11, 21, 23, 6, 'UTC') }

  context 'decode_pay_req' do
    let(:code) do
      'lnbc20n1pjq2ywjpp5qy4mms9xqe7h3uhgtct7gt4qxmx56630xwdgenup9x73ggcsk7lsdqggaexzur9cqzpgxqyz5vqsp5je8mp8d49gvq0hj37jkp6y7vapvsgc6nflehhwpqw0yznclzuuqq9qyyssqt38umwt9wdd09dgejd68v88jnwezr9j2y87pv3yr5yglw77kqk6hn3jv6ue573m003n06r2yfa8yzzyh8zr3rgkkwqg9sf4arv490eqps7h0k9'
    end

    it 'adapts' do
      raw = VCR.tape.replay('lightning.decode_pay_req', pay_req: code) do
        Lighstorm::Ports::GRPC.lightning.decode_pay_req(pay_req: code).to_h
      end

      Contract.expect(
        raw, 'd55fb253f865f7080aebe148970d9d0a53c34aea42bcefe416231344b5f75d2c'
      ) do |actual, expected|
        expect(actual.hash).to eq(expected.hash)
        expect(actual.contract).to eq(expected.contract)
      end

      adapted = described_class.decode_pay_req(raw)

      Contract.expect(
        adapted, 'ff7ca6b569cce1b9b3f718171727c825cb001bc96fec0956ab1698c0edc30d64'
      ) do |actual, expected|
        expect(actual.hash).to eq(expected.hash)
        expect(actual.contract).to eq(expected.contract)

        expect(actual.contract).to eq(
          { _key: 'String:50+',
            _source: 'Symbol:11..20',
            address: 'String:50+',
            amount: { millisatoshis: 'Integer:0..10' },
            created_at: 'Time',
            expires_at: 'Time',
            description: { hash: 'Nil', memo: 'String:0..10' },
            payable: 'String:0..10',
            secret: { hash: 'String:50+' } }
        )
      end

      adapted = described_class.decode_pay_req(raw, code)

      Contract.expect(
        adapted, '13e111e67a75fe4ef14e09e6af0b06e732b2aa8597ff7ecd1cb03f0ff24ba41e'
      ) do |actual, expected|
        expect(actual.hash).to eq(expected.hash)
        expect(actual.contract).to eq(expected.contract)

        expect(actual.contract).to eq(
          { _key: 'String:50+',
            _source: 'Symbol:11..20',
            address: 'String:50+',
            amount: { millisatoshis: 'Integer:0..10' },
            code: 'String:50+',
            created_at: 'Time',
            expires_at: 'Time',
            description: { hash: 'Nil', memo: 'String:0..10' },
            payable: 'String:0..10',
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

      adapted = described_class.list_invoices(raw, at)

      Contract.expect(
        adapted, 'ebeeac84d4ebbb2d598ba14c15963bd09045358ef084c7252541355f18600b70'
      ) do |actual, expected|
        expect(actual.hash).to eq(expected.hash)
        expect(actual.contract).to eq(expected.contract)

        expect(actual.contract).to eq(
          { _key: 'String:50+',
            _source: 'Symbol:11..20',
            address: 'String:50+',
            amount: { millisatoshis: 'Integer:0..10' },
            code: 'String:50+',
            created_at: 'Time',
            expires_at: 'Time',
            description: { hash: 'Nil', memo: 'String:21..30' },
            received: { millisatoshis: 'Integer:0..10' },
            payable: 'String:0..10',
            payments: [{ amount: { millisatoshis: 'Integer:0..10' }, at: 'Time',
                         hops: [{ channel: { id: 'Integer:11..20' } }] }],
            secret: { hash: 'String:50+', preimage: 'String:50+' },
            settled_at: 'Time',
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

        adapted = described_class.lookup_invoice(raw, at)

        Contract.expect(
          adapted, 'ebeeac84d4ebbb2d598ba14c15963bd09045358ef084c7252541355f18600b70'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)

          expect(actual.contract).to eq(
            { _key: 'String:50+',
              _source: 'Symbol:11..20',
              address: 'String:50+',
              amount: { millisatoshis: 'Integer:0..10' },
              code: 'String:50+',
              created_at: 'Time',
              expires_at: 'Time',
              description: { hash: 'Nil', memo: 'String:21..30' },
              received: { millisatoshis: 'Integer:0..10' },
              payable: 'String:0..10',
              payments: [{ amount: { millisatoshis: 'Integer:0..10' }, at: 'Time',
                           hops: [{ channel: { id: 'Integer:11..20' } }] }],
              secret: { hash: 'String:50+', preimage: 'String:50+' },
              settled_at: 'Time',
              state: 'String:0..10' }
          )
        end
      end
    end

    context 'open' do
      it 'adapts' do
        secret_hash = '0136cb78b4f421b06da07e9cc32928c62c5879e4458332c268ed087357d9a637'

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

        adapted = described_class.lookup_invoice(raw, at)

        Contract.expect(
          adapted, 'b9cb9b9d9000b028b6d900e6fbb65f6052e6ac0e271c6bc53b34a6a15ed136b8'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)

          expect(actual.contract).to eq(
            { _key: 'String:50+',
              _source: 'Symbol:11..20',
              address: 'String:50+',
              amount: { millisatoshis: 'Integer:0..10' },
              code: 'String:50+',
              created_at: 'Time',
              expires_at: 'Time',
              description: { hash: 'Nil', memo: 'String:0..10' },
              payable: 'String:0..10',
              secret: { hash: 'String:50+', preimage: 'String:50+' },
              settled_at: 'Nil',
              state: 'String:0..10' }
          )
        end
      end
    end
  end
end