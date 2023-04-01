# frozen_string_literal: true

require_relative '../../../../controllers/bitcoin_address/actions/create'
require_relative '../../../../controllers/bitcoin_address'
require_relative '../../../../models/satoshis'
require_relative '../../../../models/invoice'
require_relative '../../../../ports/dsl/lighstorm/errors'
require_relative '../../../../helpers/time_expression'
require_relative '../../../../ports/dsl/lighstorm'

RSpec.describe Lighstorm::Controllers::BitcoinAddress::Create do
  describe 'create invoice' do
    let(:vcr_key) { 'Lighstorm::Controllers::BitcoinAddress::Create' }

    context 'gradual' do
      it 'flows' do
        request = described_class.prepare

        expect(request).to eq(
          {
            service: :lightning,
            method: :new_address,
            params: {
              type: :WITNESS_PUBKEY_HASH
            }
          }
        )

        response = described_class.dispatch(
          Lighstorm::Controllers::BitcoinAddress.components,
          request
        ) do |grpc|
          VCR.reel.unsafe('I_KNOW_WHAT_I_AM_DOING').replay("#{vcr_key}/dispatch", request) { grpc.call }
        end

        adapted = described_class.adapt(response)

        adapted_to_h = adapted.clone

        expect(adapted_to_h[:at].class).to eq(Time)
        adapted_to_h[:at] = adapted_to_h[:at].utc.to_s

        expect(adapted_to_h).to eq(
          { _source: :new_address,
            _key: '50f9a2077e8b33cf30e4fa64e61ac1c82dafeb57383cf8bb52a309645af2a4c5',
            at: '2023-04-01 14:41:45 UTC',
            code: 'bcrt1qahu244843a0h2ucp32l2mevlv7y0j0csd87rfk' }
        )

        model = described_class.model(adapted, Lighstorm::Controllers::BitcoinAddress.components)

        expect(model._key.size).to eq(64)
        expect(model.at.utc.to_s).to eq('2023-04-01 14:41:45 UTC')
        expect(model.code).to eq('bcrt1qahu244843a0h2ucp32l2mevlv7y0j0csd87rfk')

        Contract.expect(
          model.to_h, '3c55996d5a7b94e6ea2f9984b2e7492053f28846024fcbb34428089c18ea6a9e'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)
        end
      end
    end

    context 'straightforward' do
      context 'preview' do
        it 'previews' do
          request = described_class.perform(
            Lighstorm::Controllers::BitcoinAddress.components,
            preview: true
          )

          expect(request).to eq(
            {
              service: :lightning,
              method: :new_address,
              params: {
                type: :WITNESS_PUBKEY_HASH
              }
            }
          )
        end
      end

      context 'perform' do
        it 'performs' do
          action = described_class.perform(
            Lighstorm::Controllers::BitcoinAddress.components
          ) do |fn, from = :fetch|
            VCR.reel.unsafe('I_KNOW_WHAT_I_AM_DOING').replay("#{vcr_key}/#{from}", { test: 'b' }) { fn.call }
          end

          expect(action.response).to eq(
            { address: 'bcrt1q3jn60h3jsamve42kr2tquum69yntgw5tm32ul8' }
          )

          expect(action.result.class).to eq(Lighstorm::Models::BitcoinAddress)

          expect(action.result._key.size).to eq(64)
          expect(action.result.at.utc.to_s).to eq('2023-04-01 14:46:27 UTC')
          expect(action.result.code).to eq('bcrt1q3jn60h3jsamve42kr2tquum69yntgw5tm32ul8')

          Contract.expect(
            action.to_h, '1aebaebc7f7893a7875d00125932d60918335312113031f0ef9d1162210978bc'
          ) do |actual, expected|
            expect(actual.hash).to eq(expected.hash)
            expect(actual.contract).to eq(expected.contract)
          end
        end
      end
    end
  end
end
