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
        request_code: 'lnbc10n1pjqnkegpp58ykalpph7w5xdmfmdqjx2xkshlylrz04q609xhr99ctqgz7uk0ssdq2gdhkven9v5cqzpgxqyz5vqsp5kpxvnm8yc3d9rwuajpc47l7uawv0tzczn4f0cc94putudpqx5z3q9qyyssq9p083thk8ed0pq0cpg4sda4nkere8qspn5g53x7fk0xdmrexrd3njj2cwpp6mpds2c08yv9mqxetjmw7w0mjpvpxsyw3dezlxsgak8gpmke2ya',
        millisatoshis: 1_000
      }
    end

    context 'timeout and expiration' do
      context 'seconds' do
        it 'times out' do
          request = described_class.prepare(
            request_code: params[:request_code],
            millisatoshis: params[:millisatoshis],
            times_out_in: { seconds: 15 }
          )

          expect(request).to eq(
            { service: :router,
              method: :send_payment_v2,
              params: {
                payment_request: 'lnbc10n1pjqnkegpp58ykalpph7w5xdmfmdqjx2xkshlylrz04q609xhr99ctqgz7uk0ssdq2gdhkven9v5cqzpgxqyz5vqsp5kpxvnm8yc3d9rwuajpc47l7uawv0tzczn4f0cc94putudpqx5z3q9qyyssq9p083thk8ed0pq0cpg4sda4nkere8qspn5g53x7fk0xdmrexrd3njj2cwpp6mpds2c08yv9mqxetjmw7w0mjpvpxsyw3dezlxsgak8gpmke2ya',
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
            request_code: params[:request_code],
            millisatoshis: params[:millisatoshis],
            times_out_in: { minutes: 1, seconds: 15 }
          )

          expect(request).to eq(
            { service: :router,
              method: :send_payment_v2,
              params: {
                payment_request: 'lnbc10n1pjqnkegpp58ykalpph7w5xdmfmdqjx2xkshlylrz04q609xhr99ctqgz7uk0ssdq2gdhkven9v5cqzpgxqyz5vqsp5kpxvnm8yc3d9rwuajpc47l7uawv0tzczn4f0cc94putudpqx5z3q9qyyssq9p083thk8ed0pq0cpg4sda4nkere8qspn5g53x7fk0xdmrexrd3njj2cwpp6mpds2c08yv9mqxetjmw7w0mjpvpxsyw3dezlxsgak8gpmke2ya',
                timeout_seconds: 75,
                allow_self_payment: true,
                amt_msat: 1000
              } }
          )
        end
      end
    end

    context 'gradual' do
      it 'flows' do
        request = described_class.prepare(
          request_code: params[:request_code],
          millisatoshis: params[:millisatoshis],
          times_out_in: { seconds: 5 }
        )

        expect(request).to eq(
          { service: :router,
            method: :send_payment_v2,
            params: {
              payment_request: params[:request_code],
              amt_msat: params[:millisatoshis],
              timeout_seconds: 5,
              allow_self_payment: true
            } }
        )

        request = described_class.prepare(
          request_code: params[:request_code],
          times_out_in: { seconds: 5 }
        )

        expect(request).to eq(
          { service: :router,
            method: :send_payment_v2,
            params: {
              payment_request: params[:request_code],
              timeout_seconds: 5,
              allow_self_payment: true
            } }
        )

        response = described_class.dispatch(request) do |grpc|
          VCR.reel.replay("#{vcr_key}/dispatch", params) { grpc.call }
        end

        data = described_class.fetch(params[:request_code]) do |fetch|
          VCR.tape.replay("#{vcr_key}/fetch", params) { fetch.call }
        end

        adapted = described_class.adapt(response, data)

        Contract.expect(
          adapted.to_h, 'd89ad7c1bbbfad15665f238baad5282c86d0d013eb9172ec3b9decbe0bb0fc7d'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)
        end

        model = described_class.model(adapted)

        expect(model.at.utc.to_s).to eq('2023-03-09 14:49:54 UTC')
        expect(model.state).to eq('succeeded')
        expect(model.amount.millisatoshis).to eq(1000)
        expect(model.fee.millisatoshis).to eq(0)
        expect(model.purpose).to eq('self-payment')

        expect(model.invoice.created_at.utc.to_s).to eq('2023-03-09 14:49:54 UTC')
        expect(model.invoice.settled_at.utc.to_s).to eq('2023-03-09 14:49:59 UTC')

        expect(model.at).to be > model.invoice.created_at
        expect(model.at).to be < model.invoice.settled_at
        expect(model.invoice.settled_at).to be > model.invoice.created_at

        expect(model.invoice.state).to be_nil
        expect(model.invoice.code).to eq(params[:request_code])
        expect(model.invoice.amount.millisatoshis).to eq(params[:millisatoshis])
        expect(model.invoice.payable).to eq('once')
        expect(model.invoice.description.memo).to be_nil
        expect(model.invoice.description.hash).to be_nil

        expect(model.hops.size).to eq(2)
        expect(model.hops.last.amount.millisatoshis).to eq(params[:millisatoshis])
      end
    end

    context 'straightforward' do
      context 'preview' do
        it 'previews' do
          request = described_class.perform(
            request_code: params[:request_code],
            times_out_in: { seconds: 5 },
            preview: true
          )

          expect(request).to eq(
            { service: :router,
              method: :send_payment_v2,
              params: {
                payment_request: params[:request_code],
                timeout_seconds: 5,
                allow_self_payment: true
              } }
          )
        end
      end

      context 'perform' do
        it 'performs' do
          action = described_class.perform(
            request_code: params[:request_code],
            times_out_in: { seconds: 5 }
          ) do |fn, from = :fetch|
            VCR.reel.replay("#{vcr_key}/#{from}", params) { fn.call }
          end

          expect(action.response.first[:creation_time_ns].to_s.size).to eq(19)
          expect(action.result.class).to eq(Lighstorm::Models::Payment)

          expect(action.result.at.utc.to_s).to eq('2023-03-09 14:49:54 UTC')
          expect(action.result.state).to eq('succeeded')
          expect(action.result.amount.millisatoshis).to eq(1000)
          expect(action.result.fee.millisatoshis).to eq(0)
          expect(action.result.purpose).to eq('self-payment')

          expect(action.result.invoice.created_at.utc.to_s).to eq('2023-03-09 14:49:54 UTC')
          expect(action.result.invoice.settled_at.utc.to_s).to eq('2023-03-09 14:49:59 UTC')
          expect(action.result.invoice.state).to be_nil
          expect(action.result.invoice.code).to eq(params[:request_code])
          expect(action.result.invoice.amount.millisatoshis).to eq(params[:millisatoshis])
          expect(action.result.invoice.payable).to eq('once')
          expect(action.result.invoice.description.memo).to be_nil
          expect(action.result.invoice.description.hash).to be_nil

          expect(action.result.hops.size).to eq(2)
          expect(action.result.hops.last.amount.millisatoshis).to eq(params[:millisatoshis])

          Contract.expect(
            action.to_h, 'e982a27619a6f2bf75935675dff1d9bb489db7bf894484e7816cf83e31a31043'
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
            request_code: params[:request_code],
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
          request_code: 'lnbc10n1pjqhfldpp502qqwwx8gxks3l0c05uj7a4f072206d2vt7m632nve5l4wzf07hsdqcg3hkuct5v5srz6eqd4ekzarncqzpgxqyz5vqsp5lmj5suzpg93uhk5268lk6axn3gz3dvamcg5n6fcgskr8968spwwq9q8pqqqssq0qced26llyuk3583yrf7yhq4mt89nnd8tnrelm6dmap2gp0wva736ppgdrj9gvl5pvupkm8lvnhx36nkpfjq6seduzjysggcwuv3sgqpynrw75',
          millisatoshis: 1_000
        }
      end

      it 'performs' do
        action = described_class.perform(
          request_code: params[:request_code],
          times_out_in: { seconds: 5 }
        ) do |fn, from = :fetch|
          VCR.reel.replay("#{vcr_key}/#{from}", params) { fn.call }
        end

        expect(action.response.first[:creation_time_ns].to_s.size).to eq(19)
        expect(action.result.class).to eq(Lighstorm::Models::Payment)

        expect(action.result.at.utc.to_s).to eq('2023-03-10 22:41:06 UTC')
        expect(action.result.state).to eq('succeeded')
        expect(action.result.amount.millisatoshis).to eq(1000)
        expect(action.result.fee.millisatoshis).to eq(0)
        expect(action.result.purpose).to eq('self-payment')

        expect(action.result.invoice.created_at.utc.to_s).to eq('2023-03-10 22:41:06 UTC')
        expect(action.result.invoice.settled_at.utc.to_s).to eq('2023-03-10 22:41:10 UTC')
        expect(action.result.invoice.state).to be_nil
        expect(action.result.invoice.code).to eq(params[:request_code])
        expect(action.result.invoice.amount.millisatoshis).to eq(params[:millisatoshis])
        expect(action.result.invoice.payable).to eq('once')
        expect(action.result.invoice.description.memo).to be_nil
        expect(action.result.invoice.description.hash).to be_nil

        expect(action.result.hops.size).to eq(2)
        expect(action.result.hops.last.amount.millisatoshis).to eq(params[:millisatoshis])

        Contract.expect(
          action.to_h, 'e982a27619a6f2bf75935675dff1d9bb489db7bf894484e7816cf83e31a31043'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)
        end
      end
    end

    context 'errors' do
      context 'already paid' do
        it 'raises error' do
          expect do
            described_class.perform(
              request_code: params[:request_code],
              times_out_in: { seconds: 5 }
            ) do |fn, from = :fetch|
              VCR.reel.replay("#{vcr_key}/#{from}/already-paid", params) { fn.call }
            end
          end.to raise_error AlreadyPaidError, 'The invoice is already paid.'

          begin
            described_class.perform(
              request_code: params[:request_code],
              times_out_in: { seconds: 5 }
            ) do |fn, from = :fetch|
              VCR.reel.replay("#{vcr_key}/#{from}/already-paid", params) { fn.call }
            end
          rescue StandardError => e
            expect(e.grpc.class).to eq(GRPC::AlreadyExists)
            expect(e.grpc.message).to eq(
              '6:invoice is already paid. debug_error_string:{UNKNOWN:Error received from peer ipv4:127.0.0.1:10009 {created_time:"2023-03-09T12:08:45.066316581-03:00", grpc_status:6, grpc_message:"invoice is already paid"}}'
            )
          end
        end
      end

      context 'millisatoshis' do
        it 'raises error' do
          expect do
            described_class.perform(
              request_code: params[:request_code], millisatoshis: params[:millisatoshis],
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
              request_code: params[:request_code], millisatoshis: params[:millisatoshis],
              times_out_in: { seconds: 5 }
            ) do |fn, from = :fetch|
              VCR.reel.replay("#{vcr_key}/#{from}/millisatoshis", params) { fn.call }
            end
          rescue StandardError => e
            expect(e.grpc.class).to eq(GRPC::Unknown)
            expect(e.grpc.message).to eq(
              '2:amount must not be specified when paying a non-zero  amount invoice. debug_error_string:{UNKNOWN:Error received from peer ipv4:127.0.0.1:10009 {created_time:"2023-03-09T12:11:16.78336031-03:00", grpc_status:2, grpc_message:"amount must not be specified when paying a non-zero  amount invoice"}}'
            )
          end
        end
      end

      context 'missing millisatoshis' do
        let(:params) do
          {
            request_code: 'lnbc1pjq3e20pp5a3w6vjny89x4kxcnappjgjds00zqy2308g4a36z0r5uzruk9judsdqdg3hkuct5d9hkucqzpgxq9z0rgqsp5mpkrclfcj56xn8kgu5xg743l4nnujw76xgcfcc7ey4x6pf5kr8mq9q8pqqqssq2wp8qyh49r9sgpelxn8ggdeftz0cg8r4fx77yj04lx3jcv8al955mt42k7zlrpvptsspk38mgu743ee3y59rhuzsq932t26cksfv7zspjr0ja3',
            millisatoshis: 1_000
          }
        end

        it 'raises error' do
          expect do
            described_class.perform(
              request_code: params[:request_code],
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
              request_code: params[:request_code],
              times_out_in: { seconds: 5 }
            ) do |fn, from = :fetch|
              VCR.reel.replay("#{vcr_key}/#{from}/millisatoshis", params) { fn.call }
            end
          rescue StandardError => e
            expect(e.grpc.class).to eq(GRPC::Unknown)
            expect(e.grpc.message).to eq(
              '2:amount must be specified when paying a zero amount invoice. debug_error_string:{UNKNOWN:Error received from peer ipv4:127.0.0.1:10009 {created_time:"2023-03-09T12:11:49.444917646-03:00", grpc_status:2, grpc_message:"amount must be specified when paying a zero amount invoice"}}'
            )
          end
        end
      end
    end
  end
end
