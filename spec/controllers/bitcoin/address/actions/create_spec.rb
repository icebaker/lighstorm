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
        request = described_class.prepare(format: 'taproot')

        expect(request).to eq(
          {
            service: :lightning,
            method: :new_address,
            params: {
              type: :TAPROOT_PUBKEY
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
            _key: 'e36bb402a48cefa9308e2850bd3bd8916c019a90aaf365eec36c84224c52f7ad',
            code: 'bcrt1peunl67vvh76fmsdfkgyhgpmf7vf7duduw6sxulzy0xrvrsf7dxrqgstrn5',
            created_at: '2023-04-04 12:41:45 UTC' }
        )

        model = described_class.model(adapted, Lighstorm::Controller::Bitcoin::Address.components)

        expect(model._key.size).to eq(64)
        expect(model.created_at.utc.to_s).to eq('2023-04-04 12:41:45 UTC')
        expect(model.code).to eq('bcrt1peunl67vvh76fmsdfkgyhgpmf7vf7duduw6sxulzy0xrvrsf7dxrqgstrn5')

        Contract.expect(
          model.to_h, '8c2ebd984c979d5e504fa3786a5fa11de2f5952360806ee0e8e985be48e3ba84'
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
                type: :TAPROOT_PUBKEY
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
            { address: 'bcrt1pthpaqp4y30hxf5vh7y27z7yk3jh62htm9t7u3qce43dxtdqcuzssll03j4' }
          )

          expect(action.result.class).to eq(Lighstorm::Model::Bitcoin::Address)

          expect(action.result._key.size).to eq(64)
          expect(action.result.created_at.utc.to_s).to eq('2023-04-04 12:43:43 UTC')
          expect(action.result.code).to eq('bcrt1pthpaqp4y30hxf5vh7y27z7yk3jh62htm9t7u3qce43dxtdqcuzssll03j4')

          Contract.expect(
            action.to_h, '8490c5e8bf4f610cf62e323f42011daab114719631b193686ed509c0a33baa0b'
          ) do |actual, expected|
            expect(actual.hash).to eq(expected.hash)
            expect(actual.contract).to eq(expected.contract)
          end
        end
      end
    end
  end
end
