# frozen_string_literal: true

require_relative '../../../../../controllers/lightning/invoice/actions/pay'
require_relative '../../../../../models/satoshis'
require_relative '../../../../../models/lightning/invoice'
require_relative '../../../../../ports/dsl/lighstorm/errors'
require_relative '../../../../../helpers/time_expression'

RSpec.describe Lighstorm::Controller::Lightning::Invoice::Pay do
  describe 'pay invoice' do
    let(:vcr_key) { 'Controller::Lightning::Invoice::Pay' }
    let(:params) do
      {
        code: 'lnbc10n1pjzjk7mpp5pxvqe9yryz60h5d8tn6r3c4ue7pazsm5wa8nccdfh68x3dhaz2rsdq2gdhkven9v5cqzpgxqyz5vqsp5qrdzx7s378htfhah5c49t94xfyal6aecy7kahqwquwfuh0etjmnq9qyyssqr69jdp48m3mydt65gey5zqrtffha3ylz7slk9gyqy02edlv2z6rxf80xu9h7r2h8e2pk8zmsecluu5auw5x9gxypvfwggsk904apl9gq6qe5kd',
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
          Lighstorm::Controller::Lightning::Invoice.components,
          request
        ) do |grpc|
          VCR.reel.replay("#{vcr_key}/dispatch", params) { grpc.call }
        end

        data = described_class.fetch(
          Lighstorm::Controller::Lightning::Invoice.components,
          params[:code]
        ) do |fetch|
          VCR.tape.replay("#{vcr_key}/fetch", params) { fetch.call }
        end

        adapted = described_class.adapt(response, data)

        Contract.expect(
          adapted.to_h, 'edd345659b66e9a08bc372999217d638fe9046632741765369c1f754df23c75e'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)
        end

        model = described_class.model(adapted, Lighstorm::Controller::Lightning::Invoice.components)

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
            Lighstorm::Controller::Lightning::Invoice.components,
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
            Lighstorm::Controller::Lightning::Invoice.components,
            code: params[:code],
            times_out_in: { seconds: 5 }
          ) do |fn, from = :fetch|
            VCR.reel.replay("#{vcr_key}/#{from}", params) { fn.call }
          end

          expect(action.response.first[:creation_time_ns].to_s.size).to eq(19)
          expect(action.result.class).to eq(Lighstorm::Model::Lightning::Payment)

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
            action.to_h, '0e86079201a777a5b22557498ee6103b5ddf62241e7b73546d7e84aa9a925158'
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
            Lighstorm::Controller::Lightning::Invoice.components,
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
          code: 'lnbc10n1pjzjhpjpp529jkg6tddrg8u0pzruey3dpelaed3g95hnks6muvh9s0uefn4clsdqdg3hkuct5d9hkucqzpgxqyz5vqsp5armprk20j4ymfq4sw3kzsln0nlhlrgk055zhmt6lepzftnhl80gs9q8pqqqssq2s5fxddhapd22gh20dcfx5c39nw7f0fnd7smwcsyjq8tl4j4kr68jkhsqktggtg7am0mutvgd375v5npe0n5chnpuren7smsafl4jkcq7fjtnf',
          amount: { millisatoshis: 1_000 }
        }
      end

      it 'performs' do
        action = described_class.perform(
          Lighstorm::Controller::Lightning::Invoice.components,
          code: params[:code],
          times_out_in: { seconds: 5 }
        ) do |fn, from = :fetch|
          VCR.reel.replay("#{vcr_key}/#{from}", params) { fn.call }
        end

        expect(action.response.first[:creation_time_ns].to_s.size).to eq(19)
        expect(action.result.class).to eq(Lighstorm::Model::Lightning::Payment)

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
          action.to_h, '2179a0240df1c3c5cdb20c84bf2991e469274670fbb4d87c013c2e2fbc0b9025'
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
          Lighstorm::Controller::Lightning::Invoice.components,
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
              Lighstorm::Controller::Lightning::Invoice.components,
              code: params[:code],
              times_out_in: { seconds: 5 }
            ) do |fn, from = :fetch|
              VCR.reel.replay("#{vcr_key}/#{from}/already-paid", params) { fn.call }
            end
          end.to raise_error AlreadyPaidError, 'The invoice is already paid.'

          begin
            described_class.perform(
              Lighstorm::Controller::Lightning::Invoice.components,
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
              Lighstorm::Controller::Lightning::Invoice.components,
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
              Lighstorm::Controller::Lightning::Invoice.components,
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
            code: 'lnbc1pjzjh9kpp59vjnu8g2hags4g04nuh56nfcrmkghffrqep4x5m85xj7fkv2ypcsdq4facx2m3qg3hkuct5d9hkucqzpgxqyz5vqsp5t2x9adha5v5nd3tzfva7h6le5hwtefy5zguxrvh8zau5dl8w988q9q8pqqqssqlve2jq4par326aa38fahql9kkc7ldfca5l9wz0j5smd7nsqqxkeqw9qw7djv3julc8s58gj6nwmxnh6acqa0kwk6cruemj7chmdcgpspw7nw9s',
            amount: { millisatoshis: 1_000 }
          }
        end

        it 'raises error' do
          expect do
            described_class.perform(
              Lighstorm::Controller::Lightning::Invoice.components,
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
              Lighstorm::Controller::Lightning::Invoice.components,
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
