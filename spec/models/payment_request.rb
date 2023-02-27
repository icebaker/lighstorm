# frozen_string_literal: true

require_relative '../../adapters/payment_request'
require_relative '../../ports/grpc'

require_relative '../../models/payment_request'

RSpec.describe Lighstorm::Models::PaymentRequest do
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

      request = described_class.new(
        Lighstorm::Adapter::PaymentRequest.list_invoices(raw)
      )

      expect(request._key.size).to eq(64)

      expect(request.code).to eq('lnbc9823420n1p3u2xx7pp50hq2v50jg8zujs9wxqen36t2l9ptw4vsp9egu24sgmv0vkp5rxaqdpvf3hkxctv94fx2cnpd3skucm995unsv3nxsez65mpw3escqzpgxqrrsssp53fgraya36c9x3qugf5cxkls52shxzhflln6k8p7w23amkufwsycs9qyyssqffdlwu4pvvyyzy79jtkcsr97ttqy0c4fr9xrq63akg2fmfxhzruj9lz2wwnzyzmyalf7mu7vmxn3rf4az5w2c03z5axdmdnv423q9cqq62y7jd')
      expect(request.address.class).to eq(String)
      expect(request.address.size).to eq(64)

      expect(request.amount.millisatoshis).to eq(982_342_000)
      expect(request.amount.satoshis).to eq(982_342.0)

      expect(request.description.memo).to eq('Local-Rebalance-982342-Sats')
      expect(request.description.hash).to be_nil

      expect(request.secret.preimage.class).to eq(String)
      expect(request.secret.preimage.size).to eq(64)
      expect(request.secret.hash).to eq('7dc0a651f241c5c940ae303338e96af942b7559009728e2ab046d8f6583419ba')

      Contract.expect(
        request.to_h, '1cab5ff24fc0e2654b2a1d25421e9e020cb3f93534955e33fcbd21f75d37caa9'
      ) do |actual, expected|
        expect(actual.hash).to eq(expected.hash)
        expect(actual.contract).to eq(expected.contract)

        expect(actual.contract).to eq(
          { _key: 'String:50+',
            code: 'String:50+',
            description: {
              memo: 'String:21..30',
              hash: 'Nil'
            },
            secret: { hash: 'String:50+' } }
        )
      end
    end
  end
end
