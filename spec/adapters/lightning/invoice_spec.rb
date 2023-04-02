# frozen_string_literal: true

require_relative '../../../adapters/lightning/invoice'
require_relative '../../../ports/grpc'

RSpec.describe Lighstorm::Adapter::Lightning::Invoice do
  let(:at) { Time.new(2023, 3, 11, 21, 23, 6, 'UTC') }

  context 'decode_pay_req' do
    let(:code) do
      'lnbcrt50n1pjzvrrvpp5dgfapy5vkca6p7fanfm224yt6xdvghh78lqxtex47e44zuunxqvqdqv2pshyarfv9kqcqzpgxqyz5vqsp5uh3dwq6udfhadl2ylcegvdd6tty47mhxc5fj76wxuzaevvvtkpks9q8pqqqssq7phls6h30krygf5yh5jnkp2avmdw3kjuluppe56k5krk08rp0hnsptcjpwgdnnj33txf778ss4d34cxddd6ph9c7zfcf6c0m5kf2gvsqvwtca4'
    end

    it 'adapts' do
      raw = VCR.tape.replay('lightning.decode_pay_req', pay_req: code) do
        Lighstorm::Ports::GRPC.lightning.decode_pay_req(pay_req: code).to_h
      end

      Contract.expect(
        raw, 'a40636d9ac1a58442346846dd33494f96b0c977bbc27fee0dd1c348656e57d49'
      ) do |actual, expected|
        expect(actual.hash).to eq(expected.hash)
        expect(actual.contract).to eq(expected.contract)
      end

      adapted = described_class.decode_pay_req(raw)

      Contract.expect(
        adapted, '53470d32a22e9e698d14e8b6a922b8059a74ac6a4828b6d4641d86f24b6ffa34'
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
            payable: 'String:11..20',
            secret: { hash: 'String:50+' } }
        )
      end

      adapted = described_class.decode_pay_req(raw, code)

      Contract.expect(
        adapted, '8e556427fc08c6403dc5ab6499a121e07e47b058d9aa6fee24e49435bd7c5864'
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
            payable: 'String:11..20',
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
        raw, '0fd5246e544d34600436b0adf82c49bbf9f9abe1b9536761249f7a2e0e6690fa'
      ) do |actual, expected|
        expect(actual.hash).to eq(expected.hash)
        expect(actual.contract).to eq(expected.contract)
      end

      adapted = described_class.list_invoices(raw, at)

      Contract.expect(
        adapted, 'e66cb0d049021a3fa3cdc12c2fc3a68f760918aa0e7190a19b94ba6f2c030597'
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
            received: { millisatoshis: 'Integer:0..10' },
            payable: 'String:0..10',
            payments: [{ amount: { millisatoshis: 'Integer:0..10' }, at: 'Time',
                         hops: [{ channel: { id: 'Integer:11..20' } }] }],
            secret: { hash: 'String:50+', proof: 'String:50+' },
            settled_at: 'Time',
            state: 'String:0..10' }
        )
      end
    end
  end

  context 'lookup_invoice' do
    context 'settled' do
      it 'adapts' do
        secret_hash = 'af6c2d05f3f9379ebbd5f25a4dcbc805ca683f2292816cde8b7331aea5b1725c'

        raw = VCR.tape.replay("lightning.lookup_invoice/#{secret_hash}") do
          Lighstorm::Ports::GRPC.lightning.lookup_invoice(
            r_hash_str: secret_hash
          ).to_h
        end

        Contract.expect(
          raw, '0fd5246e544d34600436b0adf82c49bbf9f9abe1b9536761249f7a2e0e6690fa'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)
        end

        adapted = described_class.lookup_invoice(raw, at)

        Contract.expect(
          adapted, '6212dde2ebe0a44a74c97a57bdfc09a33c31f48666eaed2aca244d9f29fa2fa4'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)

          expect(actual.contract).to eq(
            { _key: 'String:50+',
              _source: 'Symbol:11..20',
              address: 'String:50+',
              code: 'String:50+',
              created_at: 'Time',
              description: { hash: 'Nil', memo: 'Nil' },
              expires_at: 'Time',
              payable: 'String:0..10',
              payments: [{ amount: { millisatoshis: 'Integer:0..10' }, at: 'Time',
                           hops: [{ channel: { id: 'Integer:11..20' } }] }],
              received: { millisatoshis: 'Integer:0..10' },
              secret: { hash: 'String:50+', proof: 'String:50+' },
              settled_at: 'Time',
              state: 'String:0..10' }
          )
        end
      end
    end

    context 'open' do
      it 'adapts' do
        secret_hash = '74bc607c11b0be68c049e4e0b093bf92a2825d195bdebdf220664e17d5fa228d'

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
              secret: { hash: 'String:50+', proof: 'String:50+' },
              settled_at: 'Nil',
              state: 'String:0..10' }
          )
        end
      end
    end
  end
end
