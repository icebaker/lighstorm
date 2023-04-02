# frozen_string_literal: true

require_relative '../../../../../controllers/lightning/invoice/actions/create'
require_relative '../../../../../models/satoshis'
require_relative '../../../../../models/lightning/invoice'
require_relative '../../../../../ports/dsl/lighstorm/errors'

RSpec.describe Lighstorm::Controller::Lightning::Invoice::Create do
  context 'errors' do
    context 'ArgumentError' do
      it 'raises error' do
        expect do
          described_class.prepare(payable: :twice, expires_in: { hours: 24 })
        end.to raise_error(
          Lighstorm::Errors::ArgumentError,
          "payable: accepts 'indefinitely' or 'once', 'twice' is not valid."
        )
      end
    end
  end

  context 'amp' do
    describe 'create invoice' do
      let(:vcr_key) { 'Controller::Lightning::Invoice::Create' }
      let(:params) { { description: 'Donation', payable: 'indefinitely' } }

      context 'gradual' do
        it 'flows' do
          request = described_class.prepare(
            amount: params[:amount],
            description: params[:description],
            payable: params[:payable],
            expires_in: { hours: 24 }
          )

          expect(request).to eq(
            { service: :lightning,
              method: :add_invoice,
              params: { memo: params[:description], expiry: 86_400, is_amp: true } }
          )

          response = described_class.dispatch(
            Lighstorm::Controller::Lightning::Invoice.components,
            request
          ) do |grpc|
            VCR.reel.replay("#{vcr_key}/dispatch", params) { grpc.call }
          end

          adapted = described_class.adapt(response)

          expect(adapted).to eq(
            { _source: :add_invoice,
              code: 'lnbcrt1pjz35aqpp55rul98whw4jlp8vehqwctzr3fzp67x5s8zaweypstad0j0tgh33qdqdg3hkuct5d9hkucqzpgxqyz5vqsp5cej84s93fnrn725avqhrcvs4y6720ya3pka5raupf9uhmccr30lq9q8pqqqssq0rwdfklxcvah27ljnx88f97swen9lmgm3fm726rjuz6fgvaljdm4lc5jmhlvs2z3ht4mxaf7xcyga9d3krhyn40v7dfw5pgmwez4vkspt7t4dw',
              address: '284eb5ed33e916c3a1400c7f91530350b55d9b344c92f5559b26691098de9715',
              secret: { hash: 'a0f9f29dd77565f09d99b81d8588714883af1a9038baec90305f5af93d68bc62' } }
          )

          data = described_class.fetch(
            Lighstorm::Controller::Lightning::Invoice.components,
            adapted
          ) do |fetch|
            VCR.reel.replay("#{vcr_key}/fetch", params) { fetch.call }
          end

          expect(data[:created_at].class).to eq(Time)
          data[:created_at] = data[:created_at].utc.to_s

          expect(data[:expires_at].class).to eq(Time)
          data[:expires_at] = data[:expires_at].utc.to_s

          expect(data).to eq(
            { _key: 'e65854beac3652c98881aad574d21e0cb7c25e5aef934dd2261d6cb069cf5a6c',
              created_at: '2023-04-02 01:00:16 UTC',
              expires_at: '2023-04-03 01:00:16 UTC',
              settled_at: nil,
              state: 'open',
              code: 'lnbcrt1pjz35aqpp55rul98whw4jlp8vehqwctzr3fzp67x5s8zaweypstad0j0tgh33qdqdg3hkuct5d9hkucqzpgxqyz5vqsp5cej84s93fnrn725avqhrcvs4y6720ya3pka5raupf9uhmccr30lq9q8pqqqssq0rwdfklxcvah27ljnx88f97swen9lmgm3fm726rjuz6fgvaljdm4lc5jmhlvs2z3ht4mxaf7xcyga9d3krhyn40v7dfw5pgmwez4vkspt7t4dw',
              payable: 'indefinitely',
              description: { memo: 'Donation', hash: nil },
              address: 'c801d8f533a22549cb851c211461b351a18ce3293544764eb123e36f881f52c1',
              secret: {
                proof: nil,
                hash: 'a0f9f29dd77565f09d99b81d8588714883af1a9038baec90305f5af93d68bc62'
              },
              _source: :lookup_invoice,
              known: true }
          )

          model = described_class.model(data, Lighstorm::Controller::Lightning::Invoice.components)

          expect(model.payable).to be('indefinitely')

          expect(model.to_h).to eq(
            { _key: 'e65854beac3652c98881aad574d21e0cb7c25e5aef934dd2261d6cb069cf5a6c',
              created_at: '2023-04-02 01:00:16 UTC',
              expires_at: '2023-04-03 01:00:16 UTC',
              settled_at: nil,
              payable: 'indefinitely',
              state: 'open',
              code: 'lnbcrt1pjz35aqpp55rul98whw4jlp8vehqwctzr3fzp67x5s8zaweypstad0j0tgh33qdqdg3hkuct5d9hkucqzpgxqyz5vqsp5cej84s93fnrn725avqhrcvs4y6720ya3pka5raupf9uhmccr30lq9q8pqqqssq0rwdfklxcvah27ljnx88f97swen9lmgm3fm726rjuz6fgvaljdm4lc5jmhlvs2z3ht4mxaf7xcyga9d3krhyn40v7dfw5pgmwez4vkspt7t4dw',
              amount: nil,
              received: nil,
              description: { memo: 'Donation', hash: nil },
              secret: { proof: nil, hash: 'a0f9f29dd77565f09d99b81d8588714883af1a9038baec90305f5af93d68bc62' },
              payments: nil }
          )
        end
      end

      context 'straightforward' do
        context 'preview' do
          it 'previews' do
            request = described_class.perform(
              Lighstorm::Controller::Lightning::Invoice.components,
              description: params[:description], payable: params[:payable],
              expires_in: { hours: 24 },
              preview: true
            )

            expect(request).to eq(
              { service: :lightning,
                method: :add_invoice,
                params: { memo: 'Donation', expiry: 86_400, is_amp: true } }
            )
          end
        end

        context 'perform' do
          it 'performs' do
            action = described_class.perform(
              Lighstorm::Controller::Lightning::Invoice.components,
              payable: params[:payable], description: params[:description],
              expires_in: { hours: 24 }
            ) do |fn, from = :fetch|
              VCR.reel.replay("#{vcr_key}/#{from}", params) { fn.call }
            end

            expect(action.result.class).to eq(Lighstorm::Model::Lightning::Invoice)

            result_to_h = action.result.to_h

            expect(result_to_h[:created_at].class).to eq(Time)
            result_to_h[:created_at] = result_to_h[:created_at].utc.to_s

            expect(result_to_h[:expires_at].class).to eq(Time)
            result_to_h[:expires_at] = result_to_h[:expires_at].utc.to_s

            expect(result_to_h).to eq(
              { _key: 'e65854beac3652c98881aad574d21e0cb7c25e5aef934dd2261d6cb069cf5a6c',
                created_at: '2023-04-02 01:00:16 UTC',
                expires_at: '2023-04-03 01:00:16 UTC',
                settled_at: nil,
                payable: 'indefinitely',
                state: 'open',
                code: 'lnbcrt1pjz35aqpp55rul98whw4jlp8vehqwctzr3fzp67x5s8zaweypstad0j0tgh33qdqdg3hkuct5d9hkucqzpgxqyz5vqsp5cej84s93fnrn725avqhrcvs4y6720ya3pka5raupf9uhmccr30lq9q8pqqqssq0rwdfklxcvah27ljnx88f97swen9lmgm3fm726rjuz6fgvaljdm4lc5jmhlvs2z3ht4mxaf7xcyga9d3krhyn40v7dfw5pgmwez4vkspt7t4dw',
                amount: nil,
                received: nil,
                description: { memo: 'Donation', hash: nil },
                secret: {
                  proof: nil,
                  hash: 'a0f9f29dd77565f09d99b81d8588714883af1a9038baec90305f5af93d68bc62'
                },
                payments: nil }
            )

            Contract.expect(
              action.response.to_h, '30b582f05da8835a47b0cdb08e80bade781a09d760f00f3a790ac4b107d1788e'
            ) do |actual, expected|
              expect(actual.hash).to eq(expected.hash)
              expect(actual.contract).to eq(
                {
                  add_index: 'Integer:0..10',
                  payment_addr: 'String:31..40',
                  payment_request: 'String:50+',
                  r_hash: 'String:31..40'
                }
              )
            end

            Contract.expect(
              action.to_h, '1a249a948e6df5814a0994b2ff101089e49cabf07ff28bf8bf7f205c5d9abc85'
            ) do |actual, expected|
              expect(actual.hash).to eq(expected.hash)

              expect(actual.contract).to eq(
                { request: { method: 'Symbol:11..20', params: { expiry: 'Integer:0..10', is_amp: 'Boolean', memo: 'String:0..10' }, service: 'Symbol:0..10' },
                  response: { add_index: 'Integer:0..10', payment_addr: 'String:31..40', payment_request: 'String:50+',
                              r_hash: 'String:31..40' },
                  result: { _key: 'String:50+',
                            amount: 'Nil',
                            code: 'String:50+',
                            created_at: 'Time',
                            description: { hash: 'Nil', memo: 'String:0..10' },
                            expires_at: 'Time',
                            payable: 'String:11..20',
                            payments: 'Nil',
                            received: 'Nil',
                            secret: { hash: 'String:50+', proof: 'Nil' },
                            settled_at: 'Nil',
                            state: 'String:0..10' } }
              )
            end
          end
        end
      end
    end
  end

  context 'invoice' do
    describe 'create invoice' do
      let(:vcr_key) { 'Controller::Lightning::Invoice::Create' }
      let(:params) { { amount: { millisatoshis: 1_000 }, description: 'Coffee', payable: 'once' } }

      context 'gradual' do
        it 'flows' do
          request = described_class.prepare(
            amount: params[:amount],
            description: params[:description],
            payable: params[:payable],
            expires_in: { hours: 24 }
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

          response = described_class.dispatch(
            Lighstorm::Controller::Lightning::Invoice.components,
            request
          ) do |grpc|
            VCR.reel.replay("#{vcr_key}/dispatch", params) { grpc.call }
          end

          adapted = described_class.adapt(response)

          Contract.expect(
            adapted, '6e8210660ee373ed333b96351bce88107e6810211a2e36e2eb9a966acaf0537a'
          ) do |actual, expected|
            expect(actual.hash).to eq(expected.hash)

            expect(actual.contract).to eq(
              {
                _source: 'Symbol:11..20',
                address: 'String:50+',
                code: 'String:50+',
                secret: { hash: 'String:50+' }
              }
            )
          end

          data = described_class.fetch(
            Lighstorm::Controller::Lightning::Invoice.components,
            adapted
          ) do |fetch|
            VCR.reel.replay("#{vcr_key}/fetch", params) { fetch.call }
          end

          expect(data[:created_at].class).to eq(Time)
          data[:created_at] = data[:created_at].utc.to_s

          expect(data[:expires_at].class).to eq(Time)
          data[:expires_at] = data[:expires_at].utc.to_s

          Contract.expect(
            data, '8fa49e2e403c301a59186363f0d9df759a25183f8ee68604fa3de1df8f009bf4'
          ) do |actual, expected|
            expect(actual.hash).to eq(expected.hash)

            expect(actual.contract).to eq(
              { _key: 'String:50+',
                _source: 'Symbol:11..20',
                address: 'String:50+',
                amount: { millisatoshis: 'Integer:0..10' },
                code: 'String:50+',
                created_at: 'String:21..30',
                description: { hash: 'Nil', memo: 'String:0..10' },
                expires_at: 'String:21..30',
                known: 'Boolean',
                payable: 'String:0..10',
                secret: { hash: 'String:50+', proof: 'String:50+' },
                settled_at: 'Nil',
                state: 'String:0..10' }
            )
          end

          model = described_class.model(data, Lighstorm::Controller::Lightning::Invoice.components)

          Contract.expect(
            model.to_h, '001dac92137661c295e0fa816a4c3b088a8196257980ae93f1b74e6af4e371bc'
          ) do |actual, expected|
            expect(actual.hash).to eq(expected.hash)

            expect(actual.contract).to eq(
              { _key: 'String:50+',
                amount: { millisatoshis: 'Integer:0..10' },
                code: 'String:50+',
                created_at: 'String:21..30',
                description: { hash: 'Nil', memo: 'String:0..10' },
                expires_at: 'String:21..30',
                payable: 'String:0..10',
                payments: 'Nil',
                received: 'Nil',
                secret: { hash: 'String:50+', proof: 'String:50+' },
                settled_at: 'Nil',
                state: 'String:0..10' }
            )
          end
        end
      end

      context 'straightforward' do
        context 'preview' do
          it 'previews' do
            request = described_class.perform(
              Lighstorm::Controller::Lightning::Invoice.components,
              amount: params[:amount], description: params[:description],
              payable: params[:payable],
              expires_in: { hours: 24 },
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
            action = described_class.perform(
              Lighstorm::Controller::Lightning::Invoice.components,
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

              expect(actual.contract).to eq(
                { request: { method: 'Symbol:11..20', params: { expiry: 'Integer:0..10', memo: 'String:0..10', value_msat: 'Integer:0..10' }, service: 'Symbol:0..10' },
                  response: { add_index: 'Integer:0..10', payment_addr: 'String:31..40', payment_request: 'String:50+',
                              r_hash: 'String:31..40' },
                  result: { _key: 'String:50+',
                            amount: { millisatoshis: 'Integer:0..10' },
                            code: 'String:50+',
                            created_at: 'Time',
                            description: { hash: 'Nil', memo: 'String:0..10' },
                            expires_at: 'Time',
                            payable: 'String:0..10',
                            payments: 'Nil',
                            received: 'Nil',
                            secret: { hash: 'String:50+', proof: 'String:50+' },
                            settled_at: 'Nil',
                            state: 'String:0..10' } }
              )
            end
          end
        end
      end
    end
  end
end
