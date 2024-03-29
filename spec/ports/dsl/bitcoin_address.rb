# frozen_string_literal: true

require 'json'

require_relative '../../../ports/dsl/lighstorm'
require_relative '../../../ports/dsl/lighstorm/errors'

RSpec.describe Lighstorm::Bitcoin::Address do
  describe 'create invoice' do
    let(:vcr_key) { 'Lighstorm::Bitcoin::Address::Create' }

    context 'straightforward' do
      context 'preview' do
        it 'previews' do
          request = described_class.create(preview: true)

          expect(request).to eq(
            { service: :lightning, method: :new_address, params: { type: :WITNESS_PUBKEY_HASH } }
          )
        end
      end

      context 'perform' do
        it 'performs' do
          action = described_class.create do |fn, from = :fetch|
            VCR.reel.unsafe('I_KNOW_WHAT_I_AM_DOING').replay("#{vcr_key}/#{from}", { test: 'b' }) { fn.call }
          end

          expect(action.result.class).to eq(Lighstorm::Model::Bitcoin::Address)

          Contract.expect(
            action.to_h, '03cf73d9d2ea3741b5be4c03710ed7d912e6a1ae341ba1005d9021ec87fddadf'
          ) do |actual, expected|
            expect(actual.hash).to eq(expected.hash)
            expect(actual.contract).to eq(expected.contract)
          end
        end
      end
    end

    context 'payment' do
      it 'pays' do
        address = described_class.new(
          code: 'bcrt1qq5gl3thf4ka93eluz0guweek9vmeyqyrck3py2'
        )

        expect(address.code).to eq('bcrt1qq5gl3thf4ka93eluz0guweek9vmeyqyrck3py2')

        request = address.pay(
          amount: { millisatoshis: 250_000_000 },
          fee: { satoshis_per_vitual_byte: 1 },
          preview: true
        )

        expect(request).to eq(
          { service: :lightning,
            method: :send_coins,
            params: {
              addr: 'bcrt1qq5gl3thf4ka93eluz0guweek9vmeyqyrck3py2',
              amount: 250_000,
              sat_per_vbyte: 1,
              min_confs: 6
            } }
        )

        action = address.pay(
          amount: { millisatoshis: 250_000_000 },
          fee: { satoshis_per_vitual_byte: 1 }
        ) do |fn, from = :fetch|
          VCR.reel.unsafe('I_KNOW_WHAT_I_AM_DOING').replay("#{vcr_key}/#{from}", request) { fn.call }
        end

        transaction = action.result

        expect(transaction._key.size).to eq(64)
        expect(transaction.at.utc.to_s).to eq('2023-04-02 13:14:44 UTC')
        expect(transaction.hash).to eq(action.response[:txid])
        expect(transaction.amount.millisatoshis).to eq(-250_000_000)
        expect(transaction.fee.millisatoshis).to eq(154_000)
        expect(transaction.description).to eq('external')
      end
    end
  end
end
