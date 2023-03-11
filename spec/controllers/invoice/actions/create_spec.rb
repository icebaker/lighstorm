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
            millisatoshis: params[:millisatoshis],
            description: params[:description],
            payable: params[:payable],
            expires_in: { hours: 24 }
          )

          expect(request).to eq(
            { service: :lightning,
              method: :add_invoice,
              params: { memo: params[:description], expiry: 86_400, is_amp: true } }
          )

          response = described_class.dispatch(request) do |grpc|
            VCR.reel.replay("#{vcr_key}/dispatch", params) { grpc.call }
          end

          adapted = described_class.adapt(response)

          expect(adapted).to eq(
            { _source: :add_invoice,
              code: 'lnbc1pjqeu6fpp5xnklcw455edksex46xe0mtfdgx23vzlvjh6chr5afu6vwk5yh4xsdqdg3hkuct5d9hkucqzpgxqyz5vqsp5hf535cnvephhue006zt925eem6d7sl065ku4ve494626gzqh2pls9q8pqqqssqkeq9njfd235nq2wy8zrzph8x2agmy9429wdug3mx6f9zrwxedf8y2jk55jgd8aruvue3emzxfmskvm9c7mlppaf9m8vyhmqtcaefkrcph2jpse',
              address: '59e0e2c913f91b72670b9b2ca4520d95ccd308d078d7bf45f36bb761870fce17',
              secret: { hash: '34edfc3ab4a65b6864d5d1b2fdad2d4195160bec95f58b8e9d4f34c75a84bd4d' } }
          )

          data = described_class.fetch(adapted) do |fetch|
            VCR.reel.replay("#{vcr_key}/fetch", params) { fetch.call }
          end

          expect(data[:created_at].class).to eq(Time)
          data[:created_at] = data[:created_at].utc.to_s

          expect(data[:expires_at].class).to eq(Time)
          data[:expires_at] = data[:expires_at].utc.to_s

          expect(data).to eq(
            { _key: 'c18e8ff5fc5b8003c77720a29b4fec91ad11b26433da6aa39cd320e7a1588a87',
              created_at: '2023-03-11 21:31:53 UTC',
              expires_at: '2023-03-12 21:31:53 UTC',
              settled_at: nil,
              state: 'open',
              code: 'lnbc1pjqeu6fpp5xnklcw455edksex46xe0mtfdgx23vzlvjh6chr5afu6vwk5yh4xsdqdg3hkuct5d9hkucqzpgxqyz5vqsp5hf535cnvephhue006zt925eem6d7sl065ku4ve494626gzqh2pls9q8pqqqssqkeq9njfd235nq2wy8zrzph8x2agmy9429wdug3mx6f9zrwxedf8y2jk55jgd8aruvue3emzxfmskvm9c7mlppaf9m8vyhmqtcaefkrcph2jpse',
              payable: 'indefinitely',
              description: { memo: 'Donation', hash: nil },
              address: '9fca2b43cdb2f7782ffa353890057418ba8c862bb92a086f748b61a10242a778',
              secret: { preimage: nil,
                        hash: '34edfc3ab4a65b6864d5d1b2fdad2d4195160bec95f58b8e9d4f34c75a84bd4d' },
              _source: :lookup_invoice,
              known: true }
          )

          model = described_class.model(data)

          expect(model.payable).to be('indefinitely')

          expect(model.to_h).to eq(
            { _key: 'c18e8ff5fc5b8003c77720a29b4fec91ad11b26433da6aa39cd320e7a1588a87',
              created_at: '2023-03-11 21:31:53 UTC',
              expires_at: '2023-03-12 21:31:53 UTC',
              settled_at: nil,
              payable: 'indefinitely',
              state: 'open',
              code: 'lnbc1pjqeu6fpp5xnklcw455edksex46xe0mtfdgx23vzlvjh6chr5afu6vwk5yh4xsdqdg3hkuct5d9hkucqzpgxqyz5vqsp5hf535cnvephhue006zt925eem6d7sl065ku4ve494626gzqh2pls9q8pqqqssqkeq9njfd235nq2wy8zrzph8x2agmy9429wdug3mx6f9zrwxedf8y2jk55jgd8aruvue3emzxfmskvm9c7mlppaf9m8vyhmqtcaefkrcph2jpse',
              amount: nil,
              received: nil,
              description: { memo: 'Donation', hash: nil },
              secret: { preimage: nil,
                        hash: '34edfc3ab4a65b6864d5d1b2fdad2d4195160bec95f58b8e9d4f34c75a84bd4d' },
              payments: nil }
          )
        end
      end

      context 'straightforward' do
        context 'preview' do
          it 'previews' do
            request = described_class.perform(
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
              { _key: 'c18e8ff5fc5b8003c77720a29b4fec91ad11b26433da6aa39cd320e7a1588a87',
                created_at: '2023-03-11 21:31:53 UTC',
                expires_at: '2023-03-12 21:31:53 UTC',
                settled_at: nil,
                payable: 'indefinitely',
                state: 'open',
                code: 'lnbc1pjqeu6fpp5xnklcw455edksex46xe0mtfdgx23vzlvjh6chr5afu6vwk5yh4xsdqdg3hkuct5d9hkucqzpgxqyz5vqsp5hf535cnvephhue006zt925eem6d7sl065ku4ve494626gzqh2pls9q8pqqqssqkeq9njfd235nq2wy8zrzph8x2agmy9429wdug3mx6f9zrwxedf8y2jk55jgd8aruvue3emzxfmskvm9c7mlppaf9m8vyhmqtcaefkrcph2jpse',
                amount: nil,
                received: nil,
                description: { memo: 'Donation', hash: nil },
                secret: { preimage: nil,
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
              action.to_h, '5b5b74d9a27a5f2b2a94ba9e35e0043a6622f4cbd2cbff9b9408ffc670970bba'
            ) do |actual, expected|
              expect(actual.hash).to eq(expected.hash)

              expect(actual.contract).to eq(
                { response: { add_index: 'Integer:0..10', payment_addr: 'String:31..40', payment_request: 'String:50+', r_hash: 'String:31..40' },
                  result: { _key: 'String:50+',
                            amount: 'Nil',
                            code: 'String:50+',
                            created_at: 'Time',
                            description: { hash: 'Nil', memo: 'String:0..10' },
                            expires_at: 'Time',
                            payable: 'String:11..20',
                            payments: 'Nil',
                            received: 'Nil',
                            secret: { hash: 'String:50+', preimage: 'Nil' },
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
      let(:params) { { millisatoshis: 1_000, description: 'Coffee', payable: 'once' } }

      context 'gradual' do
        it 'flows' do
          request = described_class.prepare(
            millisatoshis: params[:millisatoshis],
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
                value_msat: params[:millisatoshis]
              } }
          )

          response = described_class.dispatch(request) do |grpc|
            VCR.reel.replay("#{vcr_key}/dispatch", params) { grpc.call }
          end

          adapted = described_class.adapt(response)

          expect(adapted).to eq(
            { _source: :add_invoice,
              code: 'lnbc10n1pjqeapxpp5afdddcrmgah7elxfedzvww5nhj9vcxrwlj8qcevw87u9g8te2y0qdq2gdhkven9v5cqzpgxqyz5vqsp52q0mzygtulszvtutzpj9s7x6ucga35d05wr6ayp5vl8zx638g3ys9qyyssqwed572dyu89j80kjvss36lwg4efq3he5lqsp365l2e579ve2kap3v05hmputgkhp2tv5g6v6vfsvf3fr2lfxx7jh0jr4pns6nntn6kgqxcvx9k',
              address: 'ca569b4e7219cdde539b81e60ab1be57036310fd784ab044f43681bbeb2fda7d',
              secret: { hash: 'ea5ad6e07b476fecfcc9cb44c73a93bc8acc186efc8e0c658e3fb8541d79511e' } }
          )

          data = described_class.fetch(adapted) do |fetch|
            VCR.reel.replay("#{vcr_key}/fetch", params) { fetch.call }
          end

          expect(data[:created_at].class).to eq(Time)
          data[:created_at] = data[:created_at].utc.to_s

          expect(data[:expires_at].class).to eq(Time)
          data[:expires_at] = data[:expires_at].utc.to_s

          expect(data).to eq(
            { _key: '1da09b0a9a7a8c06bfd6e9dca4f39f070073f34a70424a864c402d5003e11d29',
              created_at: '2023-03-11 21:35:34 UTC',
              expires_at: '2023-03-12 21:35:34 UTC',
              settled_at: nil,
              state: 'open',
              code: 'lnbc10n1pjqeapxpp5afdddcrmgah7elxfedzvww5nhj9vcxrwlj8qcevw87u9g8te2y0qdq2gdhkven9v5cqzpgxqyz5vqsp52q0mzygtulszvtutzpj9s7x6ucga35d05wr6ayp5vl8zx638g3ys9qyyssqwed572dyu89j80kjvss36lwg4efq3he5lqsp365l2e579ve2kap3v05hmputgkhp2tv5g6v6vfsvf3fr2lfxx7jh0jr4pns6nntn6kgqxcvx9k',
              payable: 'once',
              description: { memo: 'Coffee', hash: nil },
              address: '515769edeed8105b5a8cc510464db5e7551a1e6e2eebdb71b3dba059f43b3b79',
              secret: { preimage: 'ff0de17c07ff648c66fc6574f1da7724f4c5664c2573e9ff14b34bb1c278e2d4',
                        hash: 'ea5ad6e07b476fecfcc9cb44c73a93bc8acc186efc8e0c658e3fb8541d79511e' },
              amount: { millisatoshis: 1000 },
              _source: :lookup_invoice,
              known: true }
          )

          model = described_class.model(data)

          expect(model.to_h).to eq(
            { _key: '1da09b0a9a7a8c06bfd6e9dca4f39f070073f34a70424a864c402d5003e11d29',
              created_at: '2023-03-11 21:35:34 UTC',
              expires_at: '2023-03-12 21:35:34 UTC',
              settled_at: nil,
              payable: 'once',
              state: 'open',
              code: 'lnbc10n1pjqeapxpp5afdddcrmgah7elxfedzvww5nhj9vcxrwlj8qcevw87u9g8te2y0qdq2gdhkven9v5cqzpgxqyz5vqsp52q0mzygtulszvtutzpj9s7x6ucga35d05wr6ayp5vl8zx638g3ys9qyyssqwed572dyu89j80kjvss36lwg4efq3he5lqsp365l2e579ve2kap3v05hmputgkhp2tv5g6v6vfsvf3fr2lfxx7jh0jr4pns6nntn6kgqxcvx9k',
              amount: { millisatoshis: 1000 },
              received: nil,
              description: { memo: 'Coffee', hash: nil },
              secret: { preimage: 'ff0de17c07ff648c66fc6574f1da7724f4c5664c2573e9ff14b34bb1c278e2d4',
                        hash: 'ea5ad6e07b476fecfcc9cb44c73a93bc8acc186efc8e0c658e3fb8541d79511e' },
              payments: nil }
          )
        end
      end

      context 'straightforward' do
        context 'preview' do
          it 'previews' do
            request = described_class.perform(
              millisatoshis: params[:millisatoshis], description: params[:description],
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
                  value_msat: params[:millisatoshis]
                } }
            )
          end
        end

        context 'perform' do
          it 'performs' do
            action = described_class.perform(
              millisatoshis: params[:millisatoshis],
              description: params[:description],
              expires_in: { hours: 24 },
              payable: params[:payable]
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
              { _key: '1da09b0a9a7a8c06bfd6e9dca4f39f070073f34a70424a864c402d5003e11d29',
                created_at: '2023-03-11 21:35:34 UTC',
                expires_at: '2023-03-12 21:35:34 UTC',
                settled_at: nil,
                payable: 'once',
                state: 'open',
                code: 'lnbc10n1pjqeapxpp5afdddcrmgah7elxfedzvww5nhj9vcxrwlj8qcevw87u9g8te2y0qdq2gdhkven9v5cqzpgxqyz5vqsp52q0mzygtulszvtutzpj9s7x6ucga35d05wr6ayp5vl8zx638g3ys9qyyssqwed572dyu89j80kjvss36lwg4efq3he5lqsp365l2e579ve2kap3v05hmputgkhp2tv5g6v6vfsvf3fr2lfxx7jh0jr4pns6nntn6kgqxcvx9k',
                amount: { millisatoshis: 1000 },
                received: nil,
                description: { memo: 'Coffee', hash: nil },
                secret: { preimage: 'ff0de17c07ff648c66fc6574f1da7724f4c5664c2573e9ff14b34bb1c278e2d4',
                          hash: 'ea5ad6e07b476fecfcc9cb44c73a93bc8acc186efc8e0c658e3fb8541d79511e' },
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
              action.to_h, 'ea450f2ebd9f6657f974b90f6dc1079c016243bbf88a5445f878ca8f862545a6'
            ) do |actual, expected|
              expect(actual.hash).to eq(expected.hash)

              expect(actual.contract).to eq(
                { response: { add_index: 'Integer:0..10', payment_addr: 'String:31..40', payment_request: 'String:50+', r_hash: 'String:31..40' },
                  result: { _key: 'String:50+',
                            amount: { millisatoshis: 'Integer:0..10' },
                            code: 'String:50+',
                            created_at: 'Time',
                            description: { hash: 'Nil', memo: 'String:0..10' },
                            expires_at: 'Time',
                            payable: 'String:0..10',
                            payments: 'Nil',
                            received: 'Nil',
                            secret: { hash: 'String:50+', preimage: 'String:50+' },
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
