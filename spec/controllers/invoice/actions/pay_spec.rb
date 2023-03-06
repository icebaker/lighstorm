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
        request_code: 'lnbc10n1pjqvcvfpp59ykuhh22v2pddqzq2zvf9kpjvzuax0jcwd9c6stuyfn96tp3fv5sdq82a5kuegcqzpgxqyz5vqsp5vz03d5wfv7vp4znr7u3t6fmgv753q2uv640ndua6g6n8mpraatss9qyyssqdjl58a4h4sy20c7js8pyzddp4e30t5jxl5quv2zjgxptq9kylkwqsss6ph5wweqvyhxq969x0urlashktqkfecjsputlva4lsf0petqq3n0xnn',
        millisatoshis: 1_000
      }
    end

    context 'gradual' do
      it 'flows' do
        request = described_class.prepare(
          request_code: params[:request_code], millisatoshis: params[:millisatoshis]
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
          adapted.to_h, '3313cdd53bd8d56807fc791b0b7a2af4eb0f701977e383d88f0e633ce324f5dd'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)
        end

        model = described_class.model(adapted)

        expect(model.status).to eq('succeeded')
        expect(model.created_at.utc.to_s).to eq('2023-03-06 21:56:53 UTC')
        expect(model.settled_at.utc.to_s).to eq('2023-03-06 21:56:58 UTC')
        expect(model.purpose).to eq('self-payment')
        expect(model.request.code).to eq(params[:request_code])
        expect(model.request.amount.millisatoshis).to eq(params[:millisatoshis])
        expect(model.hops.size).to eq(2)
        expect(model.hops.last.amount.millisatoshis).to eq(params[:millisatoshis])
      end
    end

    context 'straightforward' do
      context 'preview' do
        it 'previews' do
          request = described_class.perform(
            request_code: params[:request_code], millisatoshis: params[:millisatoshis], preview: true
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
            request_code: params[:request_code], millisatoshis: params[:millisatoshis]
          ) do |fn, from = :fetch|
            VCR.reel.replay("#{vcr_key}/#{from}", params) { fn.call }
          end

          expect(action.response.first[:creation_time_ns].to_s.size).to eq(19)
          expect(action.result.class).to eq(Lighstorm::Models::Payment)

          expect(action.result.status).to eq('succeeded')
          expect(action.result.created_at.utc.to_s).to eq('2023-03-06 21:56:53 UTC')
          expect(action.result.settled_at.utc.to_s).to eq('2023-03-06 21:56:58 UTC')
          expect(action.result.purpose).to eq('self-payment')
          expect(action.result.request.code).to eq(params[:request_code])
          expect(action.result.request.amount.millisatoshis).to eq(params[:millisatoshis])
          expect(action.result.hops.size).to eq(2)
          expect(action.result.hops.last.amount.millisatoshis).to eq(params[:millisatoshis])

          Contract.expect(
            action.to_h, 'fc62cd2caa889a2d27aa28ca6bdb9bb42d64c3c706bab3a631bc4ed6663882e4'
          ) do |actual, expected|
            expect(actual.hash).to eq(expected.hash)
            expect(actual.contract).to eq(expected.contract)
          end
        end
      end
    end
  end
end
