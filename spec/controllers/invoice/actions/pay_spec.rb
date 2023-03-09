# frozen_string_literal: true

require_relative '../../../../controllers/invoice/actions/pay'
require_relative '../../../../models/satoshis'
require_relative '../../../../models/invoice'
require_relative '../../../../ports/dsl/lighstorm/errors'

RSpec.describe Lighstorm::Controllers::Invoice::Pay do
  describe 'pay invoice' do
    let(:vcr_key) { 'Controllers::Invoice::Pay' }
    let(:params) do
      {
        request_code: 'lnbc10n1pjq3ch2pp5tjjmm2vtxe5mmhpq4kpkwsfgx03hqr8xkf8m9eaxwwcr323gaw4qdq2gdhkven9v5cqzpgxqyz5vqsp5jnk63q3g85xhtsfeuyt90zwl5838na48lcf7hfn22sf8yxx6tyqs9qyyssq2wlk567j0a8y9nnzkykr2lycvqy4qkjv0yrjcklmenw755ych7g42ggundskzs7zj0eez9nqttyjej3gdf8kh8gh6j6sdr0jv50ydjqqc6m25v',
        millisatoshis: 1_000
      }
    end

    context 'gradual' do
      it 'flows' do
        request = described_class.prepare(
          request_code: params[:request_code],
          millisatoshis: params[:millisatoshis],
          seconds: 5
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
          seconds: 5
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

        data = described_class.fetch do |fetch|
          VCR.tape.replay("#{vcr_key}/fetch", params) { fetch.call }
        end

        adapted = described_class.adapt(response, data)

        Contract.expect(
          adapted.to_h, '2413d48316048103141b8ef026bc8a8d03e6baf411aebe3212695468ac3fa7b8'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)
        end

        model = described_class.model(adapted)

        expect(model.at.utc.to_s).to eq('2023-03-08 20:38:12 UTC')
        expect(model.state).to eq('succeeded')
        expect(model.amount.millisatoshis).to eq(1000)
        expect(model.fee.millisatoshis).to eq(0)
        expect(model.purpose).to eq('self-payment')

        expect(model.invoice.created_at.utc.to_s).to eq('2023-03-08 20:38:12 UTC')
        expect(model.invoice.settled_at.utc.to_s).to eq('2023-03-08 20:38:16 UTC')

        expect(model.at).to be > model.invoice.created_at
        expect(model.at).to be < model.invoice.settled_at
        expect(model.invoice.settled_at).to be > model.invoice.created_at

        expect(model.invoice.state).to be_nil
        expect(model.invoice.code).to eq(params[:request_code])
        expect(model.invoice.amount.millisatoshis).to eq(params[:millisatoshis])
        expect(model.invoice.payable).to eq(:once)
        expect(model.invoice.address.size).to eq(64)
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
            request_code: params[:request_code], preview: true
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
            request_code: params[:request_code]
          ) do |fn, from = :fetch|
            VCR.reel.replay("#{vcr_key}/#{from}", params) { fn.call }
          end

          expect(action.response.first[:creation_time_ns].to_s.size).to eq(19)
          expect(action.result.class).to eq(Lighstorm::Models::Payment)

          expect(action.result.at.utc.to_s).to eq('2023-03-08 20:38:12 UTC')
          expect(action.result.state).to eq('succeeded')
          expect(action.result.amount.millisatoshis).to eq(1000)
          expect(action.result.fee.millisatoshis).to eq(0)
          expect(action.result.purpose).to eq('self-payment')

          expect(action.result.invoice.created_at.utc.to_s).to eq('2023-03-08 20:38:12 UTC')
          expect(action.result.invoice.settled_at.utc.to_s).to eq('2023-03-08 20:38:16 UTC')
          expect(action.result.invoice.state).to be_nil
          expect(action.result.invoice.code).to eq(params[:request_code])
          expect(action.result.invoice.amount.millisatoshis).to eq(params[:millisatoshis])
          expect(action.result.invoice.payable).to eq(:once)
          expect(action.result.invoice.address.size).to eq(64)
          expect(action.result.invoice.description.memo).to be_nil
          expect(action.result.invoice.description.hash).to be_nil

          expect(action.result.hops.size).to eq(2)
          expect(action.result.hops.last.amount.millisatoshis).to eq(params[:millisatoshis])

          Contract.expect(
            action.to_h, '4f218b6cf9cac261ffe28e92fa578a40eecb177f0fe4e0acb6a541f4e120aa60'
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

    context 'errors' do
      context 'already paid' do
        it 'raises error' do
          expect do
            described_class.perform(
              request_code: params[:request_code]
            ) do |fn, from = :fetch|
              VCR.reel.replay("#{vcr_key}/#{from}/already-paid", params) { fn.call }
            end
          end.to raise_error AlreadyPaidError, 'The invoice is already paid.'

          begin
            described_class.perform(
              request_code: params[:request_code]
            ) do |fn, from = :fetch|
              VCR.reel.replay("#{vcr_key}/#{from}/already-paid", params) { fn.call }
            end
          rescue StandardError => e
            expect(e.grpc.class).to eq(GRPC::AlreadyExists)
            expect(e.grpc.message).to eq(
              '6:invoice is already paid. debug_error_string:{UNKNOWN:Error received from peer ipv4:127.0.0.1:10009 {grpc_message:"invoice is already paid", grpc_status:6, created_time:"2023-03-08T17:39:59.94268418-03:00"}}'
            )
          end
        end
      end

      context 'millisatoshis' do
        it 'raises error' do
          expect do
            described_class.perform(
              request_code: params[:request_code], millisatoshis: params[:millisatoshis]
            ) do |fn, from = :fetch|
              VCR.reel.replay("#{vcr_key}/#{from}/millisatoshis", params) { fn.call }
            end
          end.to raise_error(
            AmountForNonZeroError,
            'Millisatoshis must not be specified when paying a non-zero amount invoice.'
          )

          begin
            described_class.perform(
              request_code: params[:request_code], millisatoshis: params[:millisatoshis]
            ) do |fn, from = :fetch|
              VCR.reel.replay("#{vcr_key}/#{from}/millisatoshis", params) { fn.call }
            end
          rescue StandardError => e
            expect(e.grpc.class).to eq(GRPC::Unknown)
            expect(e.grpc.message).to eq(
              '2:amount must not be specified when paying a non-zero  amount invoice. debug_error_string:{UNKNOWN:Error received from peer ipv4:127.0.0.1:10009 {grpc_message:"amount must not be specified when paying a non-zero  amount invoice", grpc_status:2, created_time:"2023-03-08T17:39:59.945965215-03:00"}}'
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
              request_code: params[:request_code]
            ) do |fn, from = :fetch|
              VCR.reel.replay("#{vcr_key}/#{from}/millisatoshis", params) { fn.call }
            end
          end.to raise_error(
            MissingMillisatoshisError,
            'Millisatoshis must be specified when paying a zero amount invoice.'
          )

          begin
            described_class.perform(
              request_code: params[:request_code]
            ) do |fn, from = :fetch|
              VCR.reel.replay("#{vcr_key}/#{from}/millisatoshis", params) { fn.call }
            end
          rescue StandardError => e
            expect(e.grpc.class).to eq(GRPC::Unknown)
            expect(e.grpc.message).to eq(
              '2:amount must be specified when paying a zero amount invoice. debug_error_string:{UNKNOWN:Error received from peer ipv4:127.0.0.1:10009 {grpc_message:"amount must be specified when paying a zero amount invoice", grpc_status:2, created_time:"2023-03-08T17:43:24.54179933-03:00"}}'
            )
          end
        end
      end
    end
  end
end
