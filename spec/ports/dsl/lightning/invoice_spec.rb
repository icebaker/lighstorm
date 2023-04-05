# frozen_string_literal: true

require 'json'

require_relative '../../../../ports/dsl/lighstorm'
require_relative '../../../../ports/dsl/lighstorm/errors'

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
            action.to_h, '27a60ae7a7ad33936d1d1bfbc54589a56b7c6cb1d4b7dd6fc120bed606a16423'
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
        invoice.to_h, 'e9cccab93d70f5b0da973c5f0ea0acdcfc8ea72bcdee01a87f54e342f16495d6'
      ) do |actual, expected|
        expect(actual.hash).to eq(expected.hash)
        expect(actual.contract).to eq(expected.contract)
      end
    end
  end
end
