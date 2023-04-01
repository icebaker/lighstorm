# frozen_string_literal: true

require_relative '../../../../controllers/invoice/actions/create'
require_relative '../../../../models/satoshis'
require_relative '../../../../models/invoice'
require_relative '../../../../ports/dsl/lighstorm/errors'

RSpec.describe Lighstorm::Controllers::Invoice::Create do
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
      let(:vcr_key) { 'Controllers::Invoice::Create' }
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
            Lighstorm::Controllers::Invoice.components,
            request
          ) do |grpc|
            VCR.reel.replay("#{vcr_key}/dispatch", params) { grpc.call }
          end

          adapted = described_class.adapt(response)

          expect(adapted).to eq(
            { _source: :add_invoice,
              code: 'lnbc1pjqeu6fpp5xnklcw455edksex46xe0mtfdgx23vzlvjh6chr5afu6vwk5yh4xsdqdg3hkuct5d9hkucqzpgxqyz5vqsp5hf535cnvephhue006zt925eem6d7sl065ku4ve494626gzqh2pls9q8pqqqssqkeq9njfd235nq2wy8zrzph8x2agmy9429wdug3mx6f9zrwxedf8y2jk55jgd8aruvue3emzxfmskvm9c7mlppaf9m8vyhmqtcaefkrcph2jpse',
              address: '59e0e2c913f91b72670b9b2ca4520d95ccd308d078d7bf45f36bb761870fce17',
              secret: { hash: '34edfc3ab4a65b6864d5d1b2fdad2d4195160bec95f58b8e9d4f34c75a84bd4d' } }
          )

          data = described_class.fetch(
            Lighstorm::Controllers::Invoice.components,
            adapted
          ) do |fetch|
            VCR.reel.replay("#{vcr_key}/fetch", params) { fetch.call }
          end

          expect(data[:created_at].class).to eq(Time)
          data[:created_at] = data[:created_at].utc.to_s

          expect(data[:expires_at].class).to eq(Time)
          data[:expires_at] = data[:expires_at].utc.to_s

          expect(data).to eq(
            { _key: 'd0abbe35b45e3a71d612b9176d4b6c4fbf738556e9b5ab05e24f677bbc24eedd',
              created_at: '2023-03-11 21:31:53 UTC',
              expires_at: '2023-03-12 21:31:53 UTC',
              settled_at: nil,
              state: 'canceled',
              code: 'lnbc1pjqeu6fpp5xnklcw455edksex46xe0mtfdgx23vzlvjh6chr5afu6vwk5yh4xsdqdg3hkuct5d9hkucqzpgxqyz5vqsp5hf535cnvephhue006zt925eem6d7sl065ku4ve494626gzqh2pls9q8pqqqssqkeq9njfd235nq2wy8zrzph8x2agmy9429wdug3mx6f9zrwxedf8y2jk55jgd8aruvue3emzxfmskvm9c7mlppaf9m8vyhmqtcaefkrcph2jpse',
              payable: 'indefinitely',
              description: { memo: 'Donation', hash: nil },
              address: '7a9563c5df0c99a3a39beb93e84531377deedfeb1821c88d1dcab63df4194c30',
              secret: { proof: nil,
                        hash: '34edfc3ab4a65b6864d5d1b2fdad2d4195160bec95f58b8e9d4f34c75a84bd4d' },
              _source: :lookup_invoice,
              known: true }
          )

          model = described_class.model(data, Lighstorm::Controllers::Invoice.components)

          expect(model.payable).to be('indefinitely')

          expect(model.to_h).to eq(
            { _key: 'd0abbe35b45e3a71d612b9176d4b6c4fbf738556e9b5ab05e24f677bbc24eedd',
              created_at: '2023-03-11 21:31:53 UTC',
              expires_at: '2023-03-12 21:31:53 UTC',
              settled_at: nil,
              payable: 'indefinitely',
              state: 'canceled',
              code: 'lnbc1pjqeu6fpp5xnklcw455edksex46xe0mtfdgx23vzlvjh6chr5afu6vwk5yh4xsdqdg3hkuct5d9hkucqzpgxqyz5vqsp5hf535cnvephhue006zt925eem6d7sl065ku4ve494626gzqh2pls9q8pqqqssqkeq9njfd235nq2wy8zrzph8x2agmy9429wdug3mx6f9zrwxedf8y2jk55jgd8aruvue3emzxfmskvm9c7mlppaf9m8vyhmqtcaefkrcph2jpse',
              amount: nil,
              received: nil,
              description: { memo: 'Donation', hash: nil },
              secret: { proof: nil,
                        hash: '34edfc3ab4a65b6864d5d1b2fdad2d4195160bec95f58b8e9d4f34c75a84bd4d' },
              payments: nil }
          )
        end
      end

      context 'straightforward' do
        context 'preview' do
          it 'previews' do
            request = described_class.perform(
              Lighstorm::Controllers::Invoice.components,
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
              Lighstorm::Controllers::Invoice.components,
              payable: params[:payable], description: params[:description],
              expires_in: { hours: 24 }
            ) do |fn, from = :fetch|
              VCR.reel.replay("#{vcr_key}/#{from}", params) { fn.call }
            end

            expect(action.result.class).to eq(Lighstorm::Models::Invoice)

            result_to_h = action.result.to_h

            expect(result_to_h[:created_at].class).to eq(Time)
            result_to_h[:created_at] = result_to_h[:created_at].utc.to_s

            expect(result_to_h[:expires_at].class).to eq(Time)
            result_to_h[:expires_at] = result_to_h[:expires_at].utc.to_s

            expect(result_to_h).to eq(
              { _key: 'd0abbe35b45e3a71d612b9176d4b6c4fbf738556e9b5ab05e24f677bbc24eedd',
                created_at: '2023-03-11 21:31:53 UTC',
                expires_at: '2023-03-12 21:31:53 UTC',
                settled_at: nil,
                payable: 'indefinitely',
                state: 'canceled',
                code: 'lnbc1pjqeu6fpp5xnklcw455edksex46xe0mtfdgx23vzlvjh6chr5afu6vwk5yh4xsdqdg3hkuct5d9hkucqzpgxqyz5vqsp5hf535cnvephhue006zt925eem6d7sl065ku4ve494626gzqh2pls9q8pqqqssqkeq9njfd235nq2wy8zrzph8x2agmy9429wdug3mx6f9zrwxedf8y2jk55jgd8aruvue3emzxfmskvm9c7mlppaf9m8vyhmqtcaefkrcph2jpse',
                amount: nil,
                received: nil,
                description: { memo: 'Donation', hash: nil },
                secret: { proof: nil,
                          hash: '34edfc3ab4a65b6864d5d1b2fdad2d4195160bec95f58b8e9d4f34c75a84bd4d' },
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
      let(:vcr_key) { 'Controllers::Invoice::Create' }
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
            Lighstorm::Controllers::Invoice.components,
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
            Lighstorm::Controllers::Invoice.components,
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

          model = described_class.model(data, Lighstorm::Controllers::Invoice.components)

          Contract.expect(
            model.to_h, 'b91495c72a81df75ad1305d5cb88c04d67551533307c58abdadfbe3937e50b16'
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
              Lighstorm::Controllers::Invoice.components,
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
              Lighstorm::Controllers::Invoice.components,
              amount: params[:amount],
              description: params[:description],
              expires_in: { hours: 24 },
              payable: params[:payable]
            ) do |fn, from = :fetch|
              VCR.reel.replay("#{vcr_key}/#{from}", params) { fn.call }
            end

            expect(action.result.class).to eq(Lighstorm::Models::Invoice)

            Contract.expect(
              action.to_h, '82c71a396189e75f20cf76a2f74ce1c12c7487fd5f9c655b7d33a841feb7160a'
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
