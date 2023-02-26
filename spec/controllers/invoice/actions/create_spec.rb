# frozen_string_literal: true

require_relative '../../../../controllers/invoice/actions/create'
require_relative '../../../../models/satoshis'
require_relative '../../../../models/invoice'
require_relative '../../../../ports/dsl/lighstorm/errors'

RSpec.describe Lighstorm::Controllers::Invoice::Create do
  describe 'create invoice' do
    let(:vcr_key) { 'Controllers::Invoice::Create' }
    let(:params) { { milisatoshis: 1_000, description: 'Coffee' } }

    context 'gradual' do
      it 'flows' do
        request = described_class.prepare(
          milisatoshis: params[:milisatoshis], description: params[:description]
        )

        expect(request).to eq(
          { service: :lightning,
            method: :add_invoice,
            params: { memo: params[:description], value_msat: params[:milisatoshis] } }
        )

        response = described_class.dispatch(request) do |grpc|
          VCR.reel.replay("#{vcr_key}/dispatch", params) { grpc.call }
        end

        adapted = described_class.adapt(response)

        expect(adapted).to eq(
          { _source: :add_invoice,
            _key: '16305600dfea1006015ab90a48d7c9ca1614e660728fd8120fd5eb38b6b7345f',
            request: { _source: :add_invoice,
                       code: 'lnbc10n1p3lkazepp5wv2zs9zj0ltkuha2zllxaee6g26x85rjn0varph6mjntgd2ytwmsdq2gdhkven9v5cqzpgxqyz5vqsp5lqfs9rzykrm55apn8zseetnk65kryzwtmpspkta6kakjezj3mfaq9qyyssqypnq4g03svs5k5fxkztftms3anjham6rkzhqlemkwtqgu0dlsf2zcmr8yl6s4xu0eerg56nfk7q0nk0xhx4xds9py3fr4djauuyu90gqjgllq5',
                       address: '8c137055e5d40cba02db6de8239bd6a1109c8e472c35b1ef86abad0ae56ce4eb',
                       secret: { hash: '73142814527fd76e5faa17fe6ee73a42b463d0729bd9d186fadca6b435445bb7' } } }
        )

        data = described_class.fetch(adapted) do |fetch|
          VCR.reel.replay("#{vcr_key}/fetch", params) { fetch.call }
        end

        expect(data[:created_at].class).to eq(Time)
        data[:created_at] = data[:created_at].utc.to_s

        expect(data).to eq(
          { _key: '2f3e6bb792f479ba97d3abdd3407e2ac016b13625628441461899f242933e099',
            created_at: '2023-02-26 15:01:45 UTC',
            settle_at: nil,
            state: 'open',
            _source: :lookup_invoice,
            request: {
              code: 'lnbc10n1p3lkazepp5wv2zs9zj0ltkuha2zllxaee6g26x85rjn0varph6mjntgd2ytwmsdq2gdhkven9v5cqzpgxqyz5vqsp5lqfs9rzykrm55apn8zseetnk65kryzwtmpspkta6kakjezj3mfaq9qyyssqypnq4g03svs5k5fxkztftms3anjham6rkzhqlemkwtqgu0dlsf2zcmr8yl6s4xu0eerg56nfk7q0nk0xhx4xds9py3fr4djauuyu90gqjgllq5',
              amount: { milisatoshis: 1000 },
              description: { memo: 'Coffee', hash: nil },
              address: '2a45d147751adffefdc8d889020b4e1d98896d3cffd79a831f830fb852eba3b6',
              secret: {
                preimage: '818abfbeb2105e5c873a1715f74ef810f757927038b224668b54ae4ac1bd60a0',
                hash: '73142814527fd76e5faa17fe6ee73a42b463d0729bd9d186fadca6b435445bb7'
              },
              _source: :lookup_invoice
            },
            known: true }
        )

        model = described_class.model(data)

        expect(model.to_h).to eq(
          { _key: '2f3e6bb792f479ba97d3abdd3407e2ac016b13625628441461899f242933e099',
            created_at: '2023-02-26 15:01:45 UTC',
            settle_at: nil,
            state: 'open',
            request: {
              _key: 'bace0935e63c3cb1e34110435d9cf9238f093ac97da7ee63f2526b4f2f99eeb3',
              code: 'lnbc10n1p3lkazepp5wv2zs9zj0ltkuha2zllxaee6g26x85rjn0varph6mjntgd2ytwmsdq2gdhkven9v5cqzpgxqyz5vqsp5lqfs9rzykrm55apn8zseetnk65kryzwtmpspkta6kakjezj3mfaq9qyyssqypnq4g03svs5k5fxkztftms3anjham6rkzhqlemkwtqgu0dlsf2zcmr8yl6s4xu0eerg56nfk7q0nk0xhx4xds9py3fr4djauuyu90gqjgllq5',
              amount: { milisatoshis: 1000 },
              description: { memo: 'Coffee', hash: nil },
              secret: { hash: '73142814527fd76e5faa17fe6ee73a42b463d0729bd9d186fadca6b435445bb7' }
            } }
        )
      end
    end

    context 'straightforward' do
      context 'preview' do
        it 'previews' do
          request = described_class.perform(
            milisatoshis: 1_000, description: 'Coffee', preview: true
          )

          expect(request).to eq(
            { service: :lightning,
              method: :add_invoice,
              params: { memo: params[:description], value_msat: params[:milisatoshis] } }
          )
        end
      end

      context 'perform' do
        it 'performs' do
          action = described_class.perform(
            milisatoshis: params[:milisatoshis], description: params[:description]
          ) do |fn, from = :fetch|
            VCR.reel.replay("#{vcr_key}/#{from}", params) { fn.call }
          end

          expect(action.result.class).to eq(Lighstorm::Models::Invoice)

          result_to_h = action.result.to_h

          expect(result_to_h[:created_at].class).to eq(Time)
          result_to_h[:created_at] = result_to_h[:created_at].utc.to_s

          expect(result_to_h).to eq(
            { _key: '2f3e6bb792f479ba97d3abdd3407e2ac016b13625628441461899f242933e099',
              created_at: '2023-02-26 15:01:45 UTC',
              settle_at: nil,
              state: 'open',
              request: {
                _key: 'bace0935e63c3cb1e34110435d9cf9238f093ac97da7ee63f2526b4f2f99eeb3',
                code: 'lnbc10n1p3lkazepp5wv2zs9zj0ltkuha2zllxaee6g26x85rjn0varph6mjntgd2ytwmsdq2gdhkven9v5cqzpgxqyz5vqsp5lqfs9rzykrm55apn8zseetnk65kryzwtmpspkta6kakjezj3mfaq9qyyssqypnq4g03svs5k5fxkztftms3anjham6rkzhqlemkwtqgu0dlsf2zcmr8yl6s4xu0eerg56nfk7q0nk0xhx4xds9py3fr4djauuyu90gqjgllq5',
                amount: { milisatoshis: 1000 },
                description: { memo: 'Coffee', hash: nil },
                secret: { hash: '73142814527fd76e5faa17fe6ee73a42b463d0729bd9d186fadca6b435445bb7' }
              } }
          )
        end
      end
    end
  end
end
