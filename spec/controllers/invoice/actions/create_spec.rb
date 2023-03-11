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
              code: 'lnbc1pjqnkz2pp5n7w280qxy53w0v6z8q9vcxt5xfe60eumfv8sk7wf2qfwywu2nxdqdqdg3hkuct5d9hkucqzpgxqyz5vqsp52xs85xveuhnrfa45zg3dax89ukh26xthp48sjtartc3fjyr77s2q9q8pqqqssqq7rk4zwqp23x90ra7hpza78gllneczdgy3n6gpatcm9afhhudv8jewjee5pf59k6lpva4kcp22sy8v2j9u3ek6nrsue93gl5u9r5trgpljxlcq',
              address: '813387143a6446376d62320aeec4c38a3f905a549dde8dd19675fe170e069150',
              secret: {
                hash: '9f9ca3bc062522e7b342380acc19743273a7e79b4b0f0b79c95012e23b8a999a'
              } }
          )

          data = described_class.fetch(adapted) do |fetch|
            VCR.reel.replay("#{vcr_key}/fetch", params) { fetch.call }
          end

          expect(data[:created_at].class).to eq(Time)
          data[:created_at] = data[:created_at].utc.to_s

          expect(data).to eq(
            { _key: '2088a8d6cee825b2b11f05ab6320211897a6cb9b41c3628a24b05e17d4ebb937',
              created_at: '2023-03-08 19:43:11 UTC',
              settled_at: nil,
              state: 'open',
              code: 'lnbc1pjq3e20pp5a3w6vjny89x4kxcnappjgjds00zqy2308g4a36z0r5uzruk9judsdqdg3hkuct5d9hkucqzpgxq9z0rgqsp5mpkrclfcj56xn8kgu5xg743l4nnujw76xgcfcc7ey4x6pf5kr8mq9q8pqqqssq2wp8qyh49r9sgpelxn8ggdeftz0cg8r4fx77yj04lx3jcv8al955mt42k7zlrpvptsspk38mgu743ee3y59rhuzsq932t26cksfv7zspjr0ja3',
              payable: 'indefinitely',
              description: { memo: 'Donation', hash: nil },
              address: '2aea2053dd044755fd4352c38f41ab6097997ee6714d7afc9e6a4164a61e39fe',
              secret: { preimage: nil,
                        hash: 'ec5da64a64394d5b1b13e8432449b07bc4022a2f3a2bd8e84f1d3821f2c5971b' },
              _source: :lookup_invoice,
              known: true }
          )

          model = described_class.model(data)

          expect(model.payable).to be('indefinitely')

          expect(model.to_h).to eq(
            { _key: '2088a8d6cee825b2b11f05ab6320211897a6cb9b41c3628a24b05e17d4ebb937',
              created_at: '2023-03-08 19:43:11 UTC',
              settled_at: nil,
              payable: 'indefinitely',
              state: 'open',
              code: 'lnbc1pjq3e20pp5a3w6vjny89x4kxcnappjgjds00zqy2308g4a36z0r5uzruk9judsdqdg3hkuct5d9hkucqzpgxq9z0rgqsp5mpkrclfcj56xn8kgu5xg743l4nnujw76xgcfcc7ey4x6pf5kr8mq9q8pqqqssq2wp8qyh49r9sgpelxn8ggdeftz0cg8r4fx77yj04lx3jcv8al955mt42k7zlrpvptsspk38mgu743ee3y59rhuzsq932t26cksfv7zspjr0ja3',
              amount: nil,
              paid: nil,
              description: { memo: 'Donation', hash: nil },
              secret: { preimage: nil,
                        hash: 'ec5da64a64394d5b1b13e8432449b07bc4022a2f3a2bd8e84f1d3821f2c5971b' },
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

            expect(result_to_h).to eq(
              { _key: '2088a8d6cee825b2b11f05ab6320211897a6cb9b41c3628a24b05e17d4ebb937',
                created_at: '2023-03-08 19:43:11 UTC',
                settled_at: nil,
                payable: 'indefinitely',
                state: 'open',
                code: 'lnbc1pjq3e20pp5a3w6vjny89x4kxcnappjgjds00zqy2308g4a36z0r5uzruk9judsdqdg3hkuct5d9hkucqzpgxq9z0rgqsp5mpkrclfcj56xn8kgu5xg743l4nnujw76xgcfcc7ey4x6pf5kr8mq9q8pqqqssq2wp8qyh49r9sgpelxn8ggdeftz0cg8r4fx77yj04lx3jcv8al955mt42k7zlrpvptsspk38mgu743ee3y59rhuzsq932t26cksfv7zspjr0ja3',
                amount: nil,
                paid: nil,
                description: { memo: 'Donation', hash: nil },
                secret: { preimage: nil,
                          hash: 'ec5da64a64394d5b1b13e8432449b07bc4022a2f3a2bd8e84f1d3821f2c5971b' },
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
              action.to_h, '92a811419f89e7a303b04b05252157c64fa27a4dedc50f568aa33c57d6ff869d'
            ) do |actual, expected|
              expect(actual.hash).to eq(expected.hash)

              expect(actual.contract).to eq(
                { response: { add_index: 'Integer:0..10', payment_addr: 'String:31..40', payment_request: 'String:50+', r_hash: 'String:31..40' },
                  result: { _key: 'String:50+',
                            amount: 'Nil',
                            code: 'String:50+',
                            created_at: 'Time',
                            description: { hash: 'Nil', memo: 'String:0..10' },
                            paid: 'Nil',
                            payable: 'String:11..20',
                            payments: 'Nil',
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
              code: 'lnbc10n1pjq3e20pp578hvxezzc092darwhpvffath3sa6jht86z8u7a2f4aua76pf7rhqdq2gdhkven9v5cqzpgxqyz5vqsp5qjvvtyyqu8xnhlhkujxpydxfxseufhuwj98hfknmsl82ln4444sq9qyyssqevcj32l3rp6t2vw2jznh7v457wf3nxmenl870hun2w2fz2kmeheswwf738esxzauc8wnzz502sxedcl0uzr9vyvdafj2fdjnzjmec5cqk7m7v7',
              address: 'd6ce1571379c58bb41729ee754ba5073337cead1d400117589a66a8eb03eaccb',
              secret: { hash: 'f1eec36442c3caa6f46eb85894f5778c3ba95d67d08fcf7549af79df6829f0ee' } }
          )

          data = described_class.fetch(adapted) do |fetch|
            VCR.reel.replay("#{vcr_key}/fetch", params) { fetch.call }
          end

          expect(data[:created_at].class).to eq(Time)
          data[:created_at] = data[:created_at].utc.to_s

          expect(data).to eq(
            { _key: '9a07be8f07c3f98d2ad8eab8ddf07689f230f76a18e578256353d34448c95030',
              created_at: '2023-03-08 19:43:11 UTC',
              settled_at: nil,
              state: 'open',
              code: 'lnbc10n1pjq3e20pp578hvxezzc092darwhpvffath3sa6jht86z8u7a2f4aua76pf7rhqdq2gdhkven9v5cqzpgxqyz5vqsp5qjvvtyyqu8xnhlhkujxpydxfxseufhuwj98hfknmsl82ln4444sq9qyyssqevcj32l3rp6t2vw2jznh7v457wf3nxmenl870hun2w2fz2kmeheswwf738esxzauc8wnzz502sxedcl0uzr9vyvdafj2fdjnzjmec5cqk7m7v7',
              payable: 'once',
              amount: { millisatoshis: 1000 },
              description: { memo: 'Coffee', hash: nil },
              address: 'c5bab382a464cf5875eafd2eb85fe22ec08d79e4a5a8c964458d8a70860ba60b',
              secret: { preimage: 'cc9d3548879dc9d1fcf2228c9be3251427d38ab0968d42b68a8e432a33a68539',
                        hash: 'f1eec36442c3caa6f46eb85894f5778c3ba95d67d08fcf7549af79df6829f0ee' },
              _source: :lookup_invoice,
              known: true }
          )

          model = described_class.model(data)

          expect(model.to_h).to eq(
            { _key: '9a07be8f07c3f98d2ad8eab8ddf07689f230f76a18e578256353d34448c95030',
              created_at: '2023-03-08 19:43:11 UTC',
              settled_at: nil,
              payable: 'once',
              state: 'open',
              code: 'lnbc10n1pjq3e20pp578hvxezzc092darwhpvffath3sa6jht86z8u7a2f4aua76pf7rhqdq2gdhkven9v5cqzpgxqyz5vqsp5qjvvtyyqu8xnhlhkujxpydxfxseufhuwj98hfknmsl82ln4444sq9qyyssqevcj32l3rp6t2vw2jznh7v457wf3nxmenl870hun2w2fz2kmeheswwf738esxzauc8wnzz502sxedcl0uzr9vyvdafj2fdjnzjmec5cqk7m7v7',
              amount: { millisatoshis: 1000 },
              paid: nil,
              description: { memo: 'Coffee', hash: nil },
              secret: { preimage: 'cc9d3548879dc9d1fcf2228c9be3251427d38ab0968d42b68a8e432a33a68539',
                        hash: 'f1eec36442c3caa6f46eb85894f5778c3ba95d67d08fcf7549af79df6829f0ee' },
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

            expect(result_to_h).to eq(
              { _key: '9a07be8f07c3f98d2ad8eab8ddf07689f230f76a18e578256353d34448c95030',
                created_at: '2023-03-08 19:43:11 UTC',
                settled_at: nil,
                payable: 'once',
                state: 'open',
                code: 'lnbc10n1pjq3e20pp578hvxezzc092darwhpvffath3sa6jht86z8u7a2f4aua76pf7rhqdq2gdhkven9v5cqzpgxqyz5vqsp5qjvvtyyqu8xnhlhkujxpydxfxseufhuwj98hfknmsl82ln4444sq9qyyssqevcj32l3rp6t2vw2jznh7v457wf3nxmenl870hun2w2fz2kmeheswwf738esxzauc8wnzz502sxedcl0uzr9vyvdafj2fdjnzjmec5cqk7m7v7',
                amount: { millisatoshis: 1000 },
                paid: nil,
                description: { memo: 'Coffee', hash: nil },
                secret: { preimage: 'cc9d3548879dc9d1fcf2228c9be3251427d38ab0968d42b68a8e432a33a68539',
                          hash: 'f1eec36442c3caa6f46eb85894f5778c3ba95d67d08fcf7549af79df6829f0ee' },
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
              action.to_h, 'd8775187ddaab8f22d36ac91d8f7bb4d6beeab456e804bb533ffc9976f89047b'
            ) do |actual, expected|
              expect(actual.hash).to eq(expected.hash)

              expect(actual.contract).to eq(
                { response: { add_index: 'Integer:0..10', payment_addr: 'String:31..40', payment_request: 'String:50+', r_hash: 'String:31..40' },
                  result: { _key: 'String:50+',
                            amount: { millisatoshis: 'Integer:0..10' },
                            code: 'String:50+',
                            created_at: 'Time',
                            description: { hash: 'Nil', memo: 'String:0..10' },
                            paid: 'Nil',
                            payable: 'String:0..10',
                            payments: 'Nil',
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
