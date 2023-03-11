# frozen_string_literal: true

require 'json'

require_relative '../../../ports/dsl/lighstorm'
require_relative '../../../ports/dsl/lighstorm/errors'

RSpec.describe Lighstorm::Invoice do
  describe 'create invoice' do
    let(:vcr_key) { 'Controllers::Invoice::Create' }
    let(:params) do
      {
        millisatoshis: 1_000,
        description: 'Coffee',
        expires_in: { hours: 24 },
        payable: 'once'
      }
    end

    context 'straightforward' do
      context 'preview' do
        it 'previews' do
          request = described_class.create(
            millisatoshis: params[:millisatoshis],
            description: params[:description],
            payable: params[:payable],
            preview: true
          )

          expect(request).to eq(
            { service: :lightning,
              method: :add_invoice,
              params: {
                memo: params[:description],
                expiry: 86_400,
                value_msat: params[:millisatoshis]
              } }
          )
        end
      end

      context 'perform' do
        it 'performs' do
          action = described_class.create(
            millisatoshis: params[:millisatoshis],
            description: params[:description],
            expires_in: { hours: 24 },
            payable: params[:payable]
          ) do |fn, from = :fetch|
            VCR.reel.replay("#{vcr_key}/#{from}", params) { fn.call }
          end

          expect(action.result.class).to eq(Lighstorm::Models::Invoice)

          Contract.expect(
            action.to_h, 'ea450f2ebd9f6657f974b90f6dc1079c016243bbf88a5445f878ca8f862545a6'
          ) do |actual, expected|
            expect(actual.hash).to eq(expected.hash)

            expect(actual.contract).to eq(expected.contract)
          end
        end
      end
    end
  end

  describe 'decode' do
    let(:vcr_key) { 'Controllers::Invoice::Decode' }
    let(:params) do
      { request_code: 'lnbc20n1pjq2ywjpp5qy4mms9xqe7h3uhgtct7gt4qxmx56630xwdgenup9x73ggcsk7lsdqggaexzur9cqzpgxqyz5vqsp5je8mp8d49gvq0hj37jkp6y7vapvsgc6nflehhwpqw0yznclzuuqq9qyyssqt38umwt9wdd09dgejd68v88jnwezr9j2y87pv3yr5yglw77kqk6hn3jv6ue573m003n06r2yfa8yzzyh8zr3rgkkwqg9sf4arv490eqps7h0k9' }
    end

    it 'decodes' do
      invoice = described_class.decode(params[:request_code]) do |fn, _from = :fetch|
        VCR.reel.replay(vcr_key.to_s, params) { fn.call }
      end

      expect(invoice.class).to eq(Lighstorm::Models::Invoice)

      invoice_to_h = invoice.to_h

      Contract.expect(
        invoice.to_h, '4a13965e8c7a02bf362b9db710a39bc4e4ca8ef3de15a6b2b14cd5681a876201'
      ) do |actual, expected|
        expect(actual.hash).to eq(expected.hash)
        expect(actual.contract).to eq(expected.contract)
      end
    end
  end
end
