# frozen_string_literal: true

require_relative '../../../../../controllers/bitcoin/address/actions/create'
require_relative '../../../../../controllers/bitcoin/address'
require_relative '../../../../../models/satoshis'
require_relative '../../../../../ports/dsl/lighstorm/errors'

RSpec.describe Lighstorm::Controller::Bitcoin::Address::Create do
  describe 'create invoice' do
    let(:vcr_key) { 'Lighstorm::Controller::Bitcoin::Address::Create' }

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
          Lighstorm::Controller::Bitcoin::Address.components,
          request
        ) do |grpc|
          VCR.reel.unsafe('I_KNOW_WHAT_I_AM_DOING').replay("#{vcr_key}/dispatch", request) { grpc.call }
        end

        adapted = described_class.adapt(response)

        adapted_to_h = adapted.clone

        expect(adapted_to_h[:created_at].class).to eq(Time)
        adapted_to_h[:created_at] = adapted_to_h[:created_at].utc.to_s

        expect(adapted_to_h).to eq(
          { _source: :new_address,
            _key: 'ed0248d083d5a9f7de6fb286f16a559525981fdc597be74da9e66a90485bc8dc',
            created_at: '2023-04-01 23:17:05 UTC',
            code: 'bcrt1qd6zttxeyr4xwn7skwrmkvkfyx3emexs5lckewx' }
        )

        model = described_class.model(adapted, Lighstorm::Controller::Bitcoin::Address.components)

        expect(model._key.size).to eq(64)
        expect(model.created_at.utc.to_s).to eq('2023-04-01 23:17:05 UTC')
        expect(model.code).to eq('bcrt1qd6zttxeyr4xwn7skwrmkvkfyx3emexs5lckewx')

        Contract.expect(
          model.to_h, '19b9b21feb645a6717f6cf43a98207f81d798c9b9d4b6523f961053d41dc746a'
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
            Lighstorm::Controller::Bitcoin::Address.components,
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
            Lighstorm::Controller::Bitcoin::Address.components
          ) do |fn, from = :fetch|
            VCR.reel.unsafe('I_KNOW_WHAT_I_AM_DOING').replay("#{vcr_key}/#{from}", { test: 'b' }) { fn.call }
          end

          expect(action.response).to eq(
            { address: 'bcrt1qhs2949xljflpxcl34ehyrwf56n75k6vj588mn9' }
          )

          expect(action.result.class).to eq(Lighstorm::Model::Bitcoin::Address)

          expect(action.result._key.size).to eq(64)
          expect(action.result.created_at.utc.to_s).to eq('2023-04-01 23:19:57 UTC')
          expect(action.result.code).to eq('bcrt1qhs2949xljflpxcl34ehyrwf56n75k6vj588mn9')

          Contract.expect(
            action.to_h, '03cf73d9d2ea3741b5be4c03710ed7d912e6a1ae341ba1005d9021ec87fddadf'
          ) do |actual, expected|
            expect(actual.hash).to eq(expected.hash)
            expect(actual.contract).to eq(expected.contract)
          end
        end
      end
    end
  end
end
