# frozen_string_literal: true

require 'json'

require_relative '../../../ports/dsl/lighstorm'
require_relative '../../../ports/dsl/lighstorm/errors'

RSpec.describe Lighstorm::Lightning::Invoice do
  describe 'create invoice' do
    let(:vcr_key) { 'Controller::Lightning::Invoice::Create' }
    let(:params) do
      {
        amount: { millisatoshis: 1_000 },
        description: 'Coffee',
        expires_in: { hours: 24 },
        payable: 'once'
      }
    end

    context 'straightforward' do
      context 'preview' do
        it 'previews' do
          request = described_class.create(
            amount: params[:amount],
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
                value_msat: params[:amount][:millisatoshis]
              } }
          )
        end
      end

      context 'perform' do
        it 'performs' do
          action = described_class.create(
            amount: params[:amount],
            description: params[:description],
            expires_in: { hours: 24 },
            payable: params[:payable]
          ) do |fn, from = :fetch|
            VCR.reel.replay("#{vcr_key}/#{from}", params) { fn.call }
          end

          expect(action.result.class).to eq(Lighstorm::Model::Lightning::Invoice)

          Contract.expect(
            action.to_h, 'f916b13ca90b63c39c8228dd88cb502ef8e2c24a69c77f8eff9495767de9d91b'
          ) do |actual, expected|
            expect(actual.hash).to eq(expected.hash)

            expect(actual.contract).to eq(expected.contract)
          end
        end
      end
    end
  end

  describe 'decode' do
    let(:vcr_key) { 'Controller::Lightning::Invoice::Decode' }
    let(:params) do
      { code: 'lnbcrt10n1pjzj72lpp55669zd5q66ncp0twj5k2lcsxl2fefpw5vkxa3c6n3x2lwmy5unmsdq6g3hkuct5v5srzgznv96x7umgdycqzpgxqyz5vqsp5xd2ejy5frcf63m80mvzxtpufh6uxrfwnpxskqnm3qu0dy8gumu2q9q8pqqqssqexmhzyyz079u9kpxnpf4mdjtqlcfeflzn8rxjkwpcgp7yyuyn8kjqf2tt2kglk7qayjwxw2ffrmwd2q32tpe6x7lvvlsu2pt4marqxqp58qnvg' }
    end

    it 'decodes' do
      invoice = described_class.decode(params[:code]) do |fn, _from = :fetch|
        VCR.reel.replay(vcr_key.to_s, params) { fn.call }
      end

      expect(invoice.class).to eq(Lighstorm::Model::Lightning::Invoice)

      invoice_to_h = invoice.to_h

      Contract.expect(
        invoice.to_h, '4b9790e53217a83aeb1614e67d4b75c86743e36cc559762f947fb5357dc36508'
      ) do |actual, expected|
        expect(actual.hash).to eq(expected.hash)
        expect(actual.contract).to eq(expected.contract)
      end
    end
  end
end
