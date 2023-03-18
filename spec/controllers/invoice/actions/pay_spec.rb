# frozen_string_literal: true

require_relative '../../../../controllers/invoice/actions/pay'
require_relative '../../../../models/satoshis'
require_relative '../../../../models/invoice'
require_relative '../../../../ports/dsl/lighstorm/errors'
require_relative '../../../../helpers/time_expression'

RSpec.describe Lighstorm::Controllers::Invoice::Pay do
  describe 'pay invoice' do
    let(:vcr_key) { 'Controllers::Invoice::Pay' }
    let(:params) do
      {
        code: 'lnbc10n1pjqe7ygpp5qwdqh8ntvx6gqv4tdw68fcyv364sparx6h8jsjmrmj537pjhsquqdq2gdhkven9v5cqzpgxqyz5vqsp55tfvg6csd96a7p9dr66n6zgqxnr2u90eym0pyllyg36nrgt8699q9qyyssqshanq8h4atvzw8jr86rcemfxn7psk34825a3lwqzmffh7mwxw6u4dts8nh4tljzpwpc0nnsskjuapc2hx8atn7fdeellgdqkxeke9hsp4cjp26',
        amount: { millisatoshis: 1_000 }
      }
    end

    context 'timeout and expiration' do
      context 'seconds' do
        it 'times out' do
          request = described_class.prepare(
            code: params[:code],
            amount: params[:amount],
            times_out_in: { seconds: 15 }
          )

          expect(request).to eq(
            { service: :router,
              method: :send_payment_v2,
              params: {
                payment_request: params[:code],
                timeout_seconds: 15,
                allow_self_payment: true,
                amt_msat: 1000
              } }
          )
        end
      end

      context 'minutes' do
        it 'times out' do
          request = described_class.prepare(
            code: params[:code],
            amount: params[:amount],
            times_out_in: { minutes: 1, seconds: 15 }
          )

          expect(request).to eq(
            { service: :router,
              method: :send_payment_v2,
              params: { payment_request: params[:code],
                        timeout_seconds: 75,
                        allow_self_payment: true,
                        amt_msat: 1000 } }
          )
        end
      end
    end

    context 'gradual' do
      it 'flows' do
        request = described_class.prepare(
          code: params[:code],
          amount: params[:amount],
          times_out_in: { seconds: 5 }
        )

        expect(request).to eq(
          { service: :router,
            method: :send_payment_v2,
            params: {
              payment_request: params[:code],
              amt_msat: params[:amount][:millisatoshis],
              timeout_seconds: 5,
              allow_self_payment: true
            } }
        )

        request = described_class.prepare(
          code: params[:code],
          times_out_in: { seconds: 5 }
        )

        expect(request).to eq(
          { service: :router,
            method: :send_payment_v2,
            params: {
              payment_request: params[:code],
              timeout_seconds: 5,
              allow_self_payment: true
            } }
        )

        response = described_class.dispatch(
          Lighstorm::Controllers::Invoice.components,
          request
        ) do |grpc|
          VCR.reel.replay("#{vcr_key}/dispatch", params) { grpc.call }
        end

        data = described_class.fetch(
          Lighstorm::Controllers::Invoice.components,
          params[:code]
        ) do |fetch|
          VCR.tape.replay("#{vcr_key}/fetch", params) { fetch.call }
        end

        adapted = described_class.adapt(response, data)

        Contract.expect(
          adapted.to_h, 'a2c2da8932aaa6c92c7de06f89ab8e0ecedf82701aa7e0acfaca195546c1cd24'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)
        end

        model = described_class.model(adapted)

        expect(model.at.utc.to_s.size).to eq(23)
        expect(model.state).to eq('succeeded')
        expect(model.amount.millisatoshis).to eq(1000)
        expect(model.fee.millisatoshis).to eq(0)
        expect(model.purpose).to eq('self-payment')

        expect(model.invoice.created_at.utc.to_s.size).to eq(23)
        expect(model.invoice.settled_at.utc.to_s.size).to eq(23)

        expect(model.at).to be > model.invoice.created_at
        expect(model.at).to be < model.invoice.settled_at
        expect(model.invoice.settled_at).to be > model.invoice.created_at

        expect(model.invoice.state).to be_nil
        expect(model.invoice.code).to eq(params[:code])
        expect(model.invoice.amount.millisatoshis).to eq(params[:amount][:millisatoshis])
        expect(model.invoice.payable).to eq('once')
        expect(model.invoice.description.memo).to be_nil
        expect(model.invoice.description.hash).to be_nil

        expect(model.hops.size).to eq(2)
        expect(model.hops.last.amount.millisatoshis).to eq(params[:amount][:millisatoshis])
      end
    end

    context 'straightforward' do
      context 'preview' do
        it 'previews' do
          request = described_class.perform(
            Lighstorm::Controllers::Invoice.components,
            code: params[:code],
            times_out_in: { seconds: 5 },
            preview: true
          )

          expect(request).to eq(
            { service: :router,
              method: :send_payment_v2,
              params: {
                payment_request: params[:code],
                timeout_seconds: 5,
                allow_self_payment: true
              } }
          )
        end
      end

      context 'perform' do
        it 'performs' do
          action = described_class.perform(
            Lighstorm::Controllers::Invoice.components,
            code: params[:code],
            times_out_in: { seconds: 5 }
          ) do |fn, from = :fetch|
            VCR.reel.replay("#{vcr_key}/#{from}", params) { fn.call }
          end

          expect(action.response.first[:creation_time_ns].to_s.size).to eq(19)
          expect(action.result.class).to eq(Lighstorm::Models::Payment)

          expect(action.result.at.utc.to_s.size).to eq(23)
          expect(action.result.state).to eq('succeeded')
          expect(action.result.amount.millisatoshis).to eq(1000)
          expect(action.result.fee.millisatoshis).to eq(0)
          expect(action.result.purpose).to eq('self-payment')

          expect(action.result.invoice.created_at.utc.to_s.size).to eq(23)
          expect(action.result.invoice.settled_at.utc.to_s.size).to eq(23)
          expect(action.result.invoice.state).to be_nil
          expect(action.result.invoice.code).to eq(params[:code])
          expect(action.result.invoice.amount.millisatoshis).to eq(params[:amount][:millisatoshis])
          expect(action.result.invoice.payable).to eq('once')
          expect(action.result.invoice.description.memo).to be_nil
          expect(action.result.invoice.description.hash).to be_nil

          expect(action.result.hops.size).to eq(2)
          expect(action.result.hops.last.amount.millisatoshis).to eq(params[:amount][:millisatoshis])

          Contract.expect(
            action.to_h, '39331542ef1158d66da20c36567c8faaf3897a93cb675e2e38e108401eb3ac8d'
          ) do |actual, expected|
            expect(actual.hash).to eq(expected.hash)
            expect(actual.contract).to eq(expected.contract)
          end
        end
      end
    end

    context 'message' do
      context 'preview' do
        it 'previews' do
          request = described_class.perform(
            Lighstorm::Controllers::Invoice.components,
            code: params[:code],
            message: 'hello!',
            times_out_in: { seconds: 5 },
            preview: true
          )

          Contract.expect(
            request, '1a67c7216cc393b4a89e9a44fbfddbb6d1227fc457f55bd9a19d806a336d17d3'
          ) do |actual, expected|
            expect(actual.hash).to eq(expected.hash)
            expect(actual.contract).to eq(
              {
                method: 'Symbol:11..20',
                params: {
                  allow_self_payment: 'Boolean',
                  dest_custom_records: {
                    34_349_334 => 'String:0..10'
                  },
                  payment_request: 'String:50+',
                  timeout_seconds: 'Integer:0..10'
                },
                service: 'Symbol:0..10'
              }
            )
          end
        end
      end
    end

    context 'amp defined' do
      let(:params) do
        {
          code: 'lnbc10n1pjq682upp5rq2kv2v6s3jzf926rg47z2jrkm993cycqla4ua05ylp2v6des0rsdqhg3hkuct5v5srzgznv968xggcqzpgxqyz5vqsp5frgwuh4v0s3aawlq40l4d4zdfym57kkes2kdn6zphy5yp42daehs9q8pqqqssqs4jaz0tlk6fzp6esjpjcgqe72hae0t5alw2dct08cj0fzam0e3554l3ukq07cmw38kvvwwsgw5wkyesatapscpjgdv20wsg958j07ggpavtnrz',
          amount: { millisatoshis: 1_000 }
        }
      end

      it 'performs' do
        action = described_class.perform(
          Lighstorm::Controllers::Invoice.components,
          code: params[:code],
          times_out_in: { seconds: 5 }
        ) do |fn, from = :fetch|
          VCR.reel.replay("#{vcr_key}/#{from}", params) { fn.call }
        end

        expect(action.response.first[:creation_time_ns].to_s.size).to eq(19)
        expect(action.result.class).to eq(Lighstorm::Models::Payment)

        expect(action.result.at.utc.to_s.size).to eq(23)
        expect(action.result.state).to eq('succeeded')
        expect(action.result.amount.millisatoshis).to eq(1000)
        expect(action.result.fee.millisatoshis).to eq(0)
        expect(action.result.purpose).to eq('self-payment')

        expect(action.result.invoice.created_at.utc.to_s.size).to eq(23)
        expect(action.result.invoice.settled_at.utc.to_s.size).to eq(23)
        expect(action.result.invoice.state).to be_nil
        expect(action.result.invoice.code).to eq(params[:code])
        expect(action.result.invoice.amount.millisatoshis).to eq(params[:amount][:millisatoshis])
        expect(action.result.invoice.payable).to eq('indefinitely')
        expect(action.result.invoice.description.memo).to be_nil
        expect(action.result.invoice.description.hash).to be_nil

        expect(action.result.hops.size).to eq(2)
        expect(action.result.hops.last.amount.millisatoshis).to eq(params[:amount][:millisatoshis])

        Contract.expect(
          action.to_h, 'dbc55f1eb55ce202298642de7ffd2a3cf9bf99d0b5b712780bef776dec7e5f67'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)
        end
      end
    end

    context 'fee' do
      let(:params) do
        {
          code: 'lnbc30u1pjq6g2xpp5sr46w8c9dddq9uqgc4mt2t3v3cnf4hzn5p2c9jlvlj6h7s422dysdqqcqzpgxqrrssrzjqvgptfurj3528snx6e3dtwepafxw5fpzdymw9pj20jj09sunnqmwqqqqqyqqqqqqqqqqqqlgqqqqqqgqjqnp4q2k4f66f04u08mwnkpx4ttpkm28z9ztxa364rr97w2tqvm7tqkmf7sp5pk7znhtnjk6msfscjufkeypg2hp64s9q9qkrantxmedq7r0r3xns9qyyssqhuneqh6y49xct5n6t6q57u4fahj7jsu997kwkauemqx5d47l7879aau7d2yx7cf2lxpq0zc4qw96cw5e4u5nzja3arkypyqyc7sy4qgqx3je87',
          amount: { millisatoshis: 3_000_000 }
        }
      end

      it 'previews millisatoshis' do
        preview = described_class.perform(
          Lighstorm::Controllers::Invoice.components,
          code: params[:code],
          fee: { maximum: { millisatoshis: 1358 } },
          times_out_in: { seconds: 5 },
          preview: true
        )

        expect(preview).to eq(
          {
            service: :router,
            method: :send_payment_v2,
            params: {
              payment_request: 'lnbc30u1pjq6g2xpp5sr46w8c9dddq9uqgc4mt2t3v3cnf4hzn5p2c9jlvlj6h7s422dysdqqcqzpgxqrrssrzjqvgptfurj3528snx6e3dtwepafxw5fpzdymw9pj20jj09sunnqmwqqqqqyqqqqqqqqqqqqlgqqqqqqgqjqnp4q2k4f66f04u08mwnkpx4ttpkm28z9ztxa364rr97w2tqvm7tqkmf7sp5pk7znhtnjk6msfscjufkeypg2hp64s9q9qkrantxmedq7r0r3xns9qyyssqhuneqh6y49xct5n6t6q57u4fahj7jsu997kwkauemqx5d47l7879aau7d2yx7cf2lxpq0zc4qw96cw5e4u5nzja3arkypyqyc7sy4qgqx3je87',
              timeout_seconds: 5,
              allow_self_payment: true,
              fee_limit_msat: 1358
            }
          }
        )
      end
    end

    context 'errors' do
      context 'already paid' do
        it 'raises error' do
          expect do
            described_class.perform(
              Lighstorm::Controllers::Invoice.components,
              code: params[:code],
              times_out_in: { seconds: 5 }
            ) do |fn, from = :fetch|
              VCR.reel.replay("#{vcr_key}/#{from}/already-paid", params) { fn.call }
            end
          end.to raise_error AlreadyPaidError, 'The invoice is already paid.'

          begin
            described_class.perform(
              Lighstorm::Controllers::Invoice.components,
              code: params[:code],
              times_out_in: { seconds: 5 }
            ) do |fn, from = :fetch|
              VCR.reel.replay("#{vcr_key}/#{from}/already-paid", params) { fn.call }
            end
          rescue StandardError => e
            expect(e.grpc.class).to eq(GRPC::AlreadyExists)
            expect(e.grpc.message).to match(/6:invoice is already paid/)
          end
        end
      end

      context 'millisatoshis' do
        it 'raises error' do
          expect do
            described_class.perform(
              Lighstorm::Controllers::Invoice.components,
              code: params[:code], amount: params[:amount],
              times_out_in: { seconds: 5 }
            ) do |fn, from = :fetch|
              VCR.reel.replay("#{vcr_key}/#{from}/millisatoshis", params) { fn.call }
            end
          end.to raise_error(
            AmountForNonZeroError,
            'Millisatoshis must not be specified when paying a non-zero amount invoice.'
          )

          begin
            described_class.perform(
              Lighstorm::Controllers::Invoice.components,
              code: params[:code], amount: params[:amount],
              times_out_in: { seconds: 5 }
            ) do |fn, from = :fetch|
              VCR.reel.replay("#{vcr_key}/#{from}/millisatoshis", params) { fn.call }
            end
          rescue StandardError => e
            expect(e.grpc.class).to eq(GRPC::Unknown)
            expect(e.grpc.message).to match(/2:amount must not be specified when paying a non-zero/)
          end
        end
      end

      context 'missing millisatoshis' do
        let(:params) do
          {
            code: 'lnbc1pjq3e20pp5a3w6vjny89x4kxcnappjgjds00zqy2308g4a36z0r5uzruk9judsdqdg3hkuct5d9hkucqzpgxq9z0rgqsp5mpkrclfcj56xn8kgu5xg743l4nnujw76xgcfcc7ey4x6pf5kr8mq9q8pqqqssq2wp8qyh49r9sgpelxn8ggdeftz0cg8r4fx77yj04lx3jcv8al955mt42k7zlrpvptsspk38mgu743ee3y59rhuzsq932t26cksfv7zspjr0ja3',
            amount: { millisatoshis: 1_000 }
          }
        end

        it 'raises error' do
          expect do
            described_class.perform(
              Lighstorm::Controllers::Invoice.components,
              code: params[:code],
              times_out_in: { seconds: 5 }
            ) do |fn, from = :fetch|
              VCR.reel.replay("#{vcr_key}/#{from}/millisatoshis", params) { fn.call }
            end
          end.to raise_error(
            MissingMillisatoshisError,
            'Millisatoshis must be specified when paying a zero amount invoice.'
          )

          begin
            described_class.perform(
              Lighstorm::Controllers::Invoice.components,
              code: params[:code],
              times_out_in: { seconds: 5 }
            ) do |fn, from = :fetch|
              VCR.reel.replay("#{vcr_key}/#{from}/millisatoshis", params) { fn.call }
            end
          rescue StandardError => e
            expect(e.grpc.class).to eq(GRPC::Unknown)
            expect(e.grpc.message).to match(/2:amount must be specified when paying a zero amount invoice/)
          end
        end
      end
    end
  end
end
