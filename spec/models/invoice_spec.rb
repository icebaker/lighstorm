# frozen_string_literal: true

require 'json'

require_relative '../../controllers/invoice/all'
require_relative '../../controllers/invoice/find_by_secret_hash'

require_relative '../../models/invoice'

require_relative '../../ports/dsl/lighstorm/errors'

RSpec.describe Lighstorm::Models::Invoice do
  describe 'all' do
    context 'settled' do
      it 'models' do
        data = Lighstorm::Controllers::Invoice::All.data do |fetch|
          VCR.tape.replay('Controllers::Invoice.all.last/memo/settled') do
            data = fetch.call

            data[:list_invoices] = [
              data[:list_invoices].reverse.find do |invoice|
                invoice[:memo] != '' && invoice[:state] == :SETTLED
              end
            ]

            data
          end
        end

        invoice = described_class.new(data[0])

        expect(invoice._key.size).to eq(64)

        expect(invoice.created_at).to be_a(Time)
        expect(invoice.created_at.utc.to_s).to eq('2023-01-16 09:29:02 UTC')

        expect(invoice.settle_at).to be_a(Time)
        expect(invoice.settle_at.utc.to_s).to eq('2023-01-16 09:29:17 UTC')

        expect(invoice.state).to eq('settled')

        expect(invoice.request._key.size).to eq(64)
        expect(invoice.request.code).to eq('lnbc9823420n1p3u2xx7pp50hq2v50jg8zujs9wxqen36t2l9ptw4vsp9egu24sgmv0vkp5rxaqdpvf3hkxctv94fx2cnpd3skucm995unsv3nxsez65mpw3escqzpgxqrrsssp53fgraya36c9x3qugf5cxkls52shxzhflln6k8p7w23amkufwsycs9qyyssqffdlwu4pvvyyzy79jtkcsr97ttqy0c4fr9xrq63akg2fmfxhzruj9lz2wwnzyzmyalf7mu7vmxn3rf4az5w2c03z5axdmdnv423q9cqq62y7jd')
        expect(invoice.request.address.class).to eq(String)
        expect(invoice.request.address.size).to eq(64)
        expect(invoice.request.amount.milisatoshis).to eq(982_342_000)
        expect(invoice.request.amount.satoshis).to eq(982_342.0)
        expect(invoice.request.description.memo).to eq('Local-Rebalance-982342-Sats')
        expect(invoice.request.description.hash).to be_nil
        expect(invoice.request.secret.preimage.class).to eq(String)
        expect(invoice.request.secret.preimage.size).to eq(64)
        expect(invoice.request.secret.hash).to eq('7dc0a651f241c5c940ae303338e96af942b7559009728e2ab046d8f6583419ba')

        Contract.expect(
          invoice.to_h, '0d75019411cea11336f7d0c9f18a4820044cc409536c6651834006ab1248a068'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)

          expect(actual.contract).to eq(
            { _key: 'String:50+',
              created_at: 'Time',
              request: { _key: 'String:50+',
                         amount: { milisatoshis: 'Integer:0..10' },
                         code: 'String:50+',
                         description: { hash: 'Nil', memo: 'String:21..30' },
                         secret: { hash: 'String:50+' } },
              settle_at: 'Time',
              state: 'String:0..10' }
          )
        end
      end
    end
  end

  describe 'find_by_secret_hash B' do
    context 'settled' do
      it 'models' do
        secret_hash = '7dc0a651f241c5c940ae303338e96af942b7559009728e2ab046d8f6583419ba'

        data = Lighstorm::Controllers::Invoice::FindBySecretHash.data(secret_hash) do |fetch|
          VCR.tape.replay("Controllers::Invoice.find_by_secret_hash/#{secret_hash}") { fetch.call }
        end

        invoice = described_class.new(data)

        expect(invoice._key.size).to eq(64)

        expect(invoice.created_at).to be_a(Time)
        expect(invoice.created_at.utc.to_s).to eq('2023-01-16 09:29:02 UTC')

        expect(invoice.settle_at).to be_a(Time)
        expect(invoice.settle_at.utc.to_s).to eq('2023-01-16 09:29:17 UTC')

        expect(invoice.state).to eq('settled')

        expect(invoice.request._key.size).to eq(64)
        expect(invoice.request.code).to eq('lnbc9823420n1p3u2xx7pp50hq2v50jg8zujs9wxqen36t2l9ptw4vsp9egu24sgmv0vkp5rxaqdpvf3hkxctv94fx2cnpd3skucm995unsv3nxsez65mpw3escqzpgxqrrsssp53fgraya36c9x3qugf5cxkls52shxzhflln6k8p7w23amkufwsycs9qyyssqffdlwu4pvvyyzy79jtkcsr97ttqy0c4fr9xrq63akg2fmfxhzruj9lz2wwnzyzmyalf7mu7vmxn3rf4az5w2c03z5axdmdnv423q9cqq62y7jd')
        expect(invoice.request.address.class).to eq(String)
        expect(invoice.request.address.size).to eq(64)
        expect(invoice.request.amount.milisatoshis).to eq(982_342_000)
        expect(invoice.request.amount.satoshis).to eq(982_342.0)
        expect(invoice.request.description.memo).to eq('Local-Rebalance-982342-Sats')
        expect(invoice.request.description.hash).to be_nil
        expect(invoice.request.secret.preimage.class).to eq(String)
        expect(invoice.request.secret.preimage.size).to eq(64)
        expect(invoice.request.secret.hash).to eq('7dc0a651f241c5c940ae303338e96af942b7559009728e2ab046d8f6583419ba')

        Contract.expect(
          invoice.to_h, '0d75019411cea11336f7d0c9f18a4820044cc409536c6651834006ab1248a068'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(
            { _key: 'String:50+',
              created_at: 'Time',
              request: { _key: 'String:50+',
                         amount: { milisatoshis: 'Integer:0..10' },
                         code: 'String:50+',
                         description: { hash: 'Nil', memo: 'String:21..30' },
                         secret: { hash: 'String:50+' } },
              settle_at: 'Time',
              state: 'String:0..10' }
          )
        end
      end
    end

    context 'open' do
      it 'models' do
        secret_hash = '0136cb78b4f421b06da07e9cc32928c62c5879e4458332c268ed087357d9a637'

        data = Lighstorm::Controllers::Invoice::FindBySecretHash.data(secret_hash) do |fetch|
          VCR.tape.replay("Controllers::Invoice.find_by_secret_hash/#{secret_hash}") { fetch.call }
        end

        invoice = described_class.new(data)

        expect(invoice._key.size).to eq(64)

        expect(invoice.created_at).to be_a(Time)
        expect(invoice.created_at.utc.to_s.size).to eq(23)

        expect(invoice.settle_at).to be_nil

        expect(invoice.state).to eq('open')

        expect(invoice.request._key.size).to eq(64)
        expect(invoice.request.code).to start_with('lnbc')
        expect(invoice.request.code.size).to eq(267)
        expect(invoice.request.address.class).to eq(String)
        expect(invoice.request.address.size).to eq(64)
        expect(invoice.request.amount.milisatoshis).to eq(1000)
        expect(invoice.request.amount.satoshis).to eq(1.0)
        expect(invoice.request.description.memo).to eq('Coffee')
        expect(invoice.request.description.hash).to be_nil
        expect(invoice.request.secret.preimage.class).to eq(String)
        expect(invoice.request.secret.preimage.size).to eq(64)
        expect(invoice.request.secret.hash).to eq(secret_hash)

        Contract.expect(
          invoice.to_h, 'b137e3031dd74ecbbc363c0f7913cec92e7803affa114000a03002a8b096d3df'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)

          expect(actual.contract).to eq(
            { _key: 'String:50+',
              created_at: 'Time',
              request: { _key: 'String:50+',
                         amount: { milisatoshis: 'Integer:0..10' },
                         code: 'String:50+',
                         description: { hash: 'Nil', memo: 'String:0..10' },
                         secret: { hash: 'String:50+' } },
              settle_at: 'Nil',
              state: 'String:0..10' }
          )
        end
      end
    end
  end
end
