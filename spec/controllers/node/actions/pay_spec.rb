# frozen_string_literal: true

require_relative '../../../../controllers/node/actions/pay'
require_relative '../../../../models/satoshis'
require_relative '../../../../ports/dsl/lighstorm/errors'

RSpec.describe Lighstorm::Controllers::Node::Pay do
  describe 'send through keysend' do
    let(:vcr_key) { 'Controllers::Node::Pay' }
    let(:params) do
      {
        through: 'keysend',
        public_key: '02d3c80335a8ccb2ed364c06875f32240f36f7edb37d80f8dbe321b4c364b6e997',
        millisatoshis: 1_000,
        message: 'hello',
        secret: {
          preimage: 'ab36558ca4d30f14dbbac393113bb6c7249aff34208aed0228859979fcc30f53',
          hash: '3cf1ed5317db6d172dd0dc91d61854d923e72958af67572478ee55c6417e7ac6'
        }
      }
    end

    context 'gradual' do
      it 'flows' do
        request = described_class.prepare(
          through: params[:through],
          public_key: params[:public_key],
          millisatoshis: params[:millisatoshis],
          secret: params[:secret],
          message: params[:message],
          seconds: 5
        )

        expect(request[:service]).to eq(:router)
        expect(request[:method]).to eq(:send_payment_v2)

        Contract.expect(
          request, '20c03c9db0d456d31cd1c38d806603f2f992e2695222ae803ebf832f8fddbbbf'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(
            { method: 'Symbol:11..20',
              params: {
                allow_self_payment: 'Boolean',
                amt_msat: 'Integer:0..10',
                dest: 'String:31..40',
                dest_custom_records: {
                  34_349_334 => 'String:0..10',
                  5_482_373_484 => 'String:31..40'
                },
                payment_hash: 'String:31..40',
                timeout_seconds: 'Integer:0..10'
              },
              service: 'Symbol:0..10' }
          )
        end

        response = described_class.dispatch(request) do |grpc|
          VCR.reel.replay("#{vcr_key}/dispatch", params) { grpc.call }
        end

        data = described_class.fetch do |fetch|
          VCR.tape.replay("#{vcr_key}/fetch", params) { fetch.call }
        end

        adapted = described_class.adapt(response, data)

        Contract.expect(
          adapted.to_h, '9f2aa869cc6d0b8603df52476494717d07f1c924c27f7dadca8b3e1b27533ebc'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)
        end

        model = described_class.model(adapted)

        expect(model.state).to eq('succeeded')
        expect(model.amount.millisatoshis).to eq(1000)
        expect(model.fee.millisatoshis).to eq(0)
        expect(model.purpose).to eq('self-payment')
        expect(model.through).to eq('keysend')
        expect(model.secret.preimage.size).to eq(64)
        expect(model.secret.hash).to eq(params[:secret][:hash])
        expect(model.hops.size).to eq(2)
        expect(model.hops.last.amount.millisatoshis).to eq(params[:millisatoshis])

        Contract.expect(
          model.to_h, '11d29a4e5ece4962c8d29f22ba48e58dc4e09e5f7dab1d8bbb0b1befa54ff6bf'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)
        end
      end
    end

    context 'straightforward' do
      context 'preview' do
        it 'previews' do
          request = described_class.perform(
            through: params[:through],
            public_key: params[:public_key],
            millisatoshis: params[:millisatoshis],
            secret: params[:secret],
            message: params[:message],
            seconds: 5,
            preview: true
          )

          expect(request[:service]).to eq(:router)
          expect(request[:method]).to eq(:send_payment_v2)

          Contract.expect(
            request, '20c03c9db0d456d31cd1c38d806603f2f992e2695222ae803ebf832f8fddbbbf'
          ) do |actual, expected|
            expect(actual.hash).to eq(expected.hash)
            expect(actual.contract).to eq(
              { method: 'Symbol:11..20',
                params: {
                  allow_self_payment: 'Boolean',
                  amt_msat: 'Integer:0..10',
                  dest: 'String:31..40',
                  dest_custom_records: {
                    34_349_334 => 'String:0..10',
                    5_482_373_484 => 'String:31..40'
                  },
                  payment_hash: 'String:31..40',
                  timeout_seconds: 'Integer:0..10'
                },
                service: 'Symbol:0..10' }
            )
          end
        end
      end

      context 'perform' do
        it 'performs' do
          action = described_class.perform(
            through: params[:through],
            public_key: params[:public_key],
            millisatoshis: params[:millisatoshis],
            secret: params[:secret],
            message: params[:message],
            seconds: 5
          ) do |fn, from = :fetch|
            VCR.reel.replay("#{vcr_key}/#{from}", params) { fn.call }
          end

          expect(action.result.class).to eq(Lighstorm::Models::Payment)

          expect(action.result.state).to eq('succeeded')
          expect(action.result.amount.millisatoshis).to eq(1000)
          expect(action.result.fee.millisatoshis).to eq(0)
          expect(action.result.purpose).to eq('self-payment')
          expect(action.result.through).to eq('keysend')
          expect(action.result.hops.size).to eq(2)
          expect(action.result.hops.last.amount.millisatoshis).to eq(params[:millisatoshis])

          Contract.expect(
            action.to_h, 'befeb3c4581320d95f039af14b898838e9b21aa22fc1fafb28703ed26d92bb60'
          ) do |actual, expected|
            expect(actual.hash).to eq(expected.hash)
            expect(actual.contract).to eq(expected.contract)
          end
        end
      end
    end
  end

  describe 'send through amp' do
    let(:vcr_key) { 'Controllers::Node::Pay' }
    let(:params) do
      {
        through: 'amp',
        public_key: '02d3c80335a8ccb2ed364c06875f32240f36f7edb37d80f8dbe321b4c364b6e997',
        millisatoshis: 1_350,
        message: 'hello',
        secret: {
          preimage: '7ec807a2d955f878ccbda17ef38cfbdce9d264b1985f3e77598b2aed17dbcead',
          hash: '843df5337eb59970990944327ded9965443df2a956b36b5b48a459eec427af27'
        }
      }
    end

    context 'gradual' do
      it 'flows' do
        request = described_class.prepare(
          through: params[:through],
          public_key: params[:public_key],
          millisatoshis: params[:millisatoshis],
          secret: params[:secret],
          message: params[:message],
          seconds: 5
        )

        expect(request[:service]).to eq(:router)
        expect(request[:method]).to eq(:send_payment_v2)

        Contract.expect(
          request, 'ab972e117b8bb7827b12197c0c37efecc3e1c6dbc998839808133f78f43c0223'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(
            { method: 'Symbol:11..20',
              params: {
                allow_self_payment: 'Boolean',
                amp: 'Boolean',
                amt_msat: 'Integer:0..10',
                dest: 'String:31..40',
                dest_custom_records: { 34_349_334 => 'String:0..10' },
                timeout_seconds: 'Integer:0..10'
              },
              service: 'Symbol:0..10' }
          )
        end

        response = described_class.dispatch(request) do |grpc|
          VCR.reel.replay("#{vcr_key}/dispatch", params) { grpc.call }
        end

        data = described_class.fetch do |fetch|
          VCR.tape.replay("#{vcr_key}/fetch", params) { fetch.call }
        end

        adapted = described_class.adapt(response, data)

        Contract.expect(
          adapted.to_h, '267e1ad9ccc9794457e2dd8ac8bf4e2471603856601810e90bca6e4784b5e5cb'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)
        end

        model = described_class.model(adapted)

        expect(model.state).to eq('succeeded')
        expect(model.amount.millisatoshis).to eq(1350)
        expect(model.fee.millisatoshis).to eq(0)
        expect(model.purpose).to eq('self-payment')
        expect(model.through).to eq('amp')
        expect(model.secret.preimage.size).to eq(64)
        expect(model.secret.hash.size).to eq(64)
        expect(model.hops.size).to eq(2)
        expect(model.hops.last.amount.millisatoshis).to eq(params[:millisatoshis])

        Contract.expect(
          model.to_h, '334112aedcfeab7c351d9d5b155bc314031f609e840ad4fef52f0a543c8187f2'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)
        end
      end
    end

    context 'straightforward' do
      context 'preview' do
        it 'previews' do
          request = described_class.perform(
            through: params[:through],
            public_key: params[:public_key],
            millisatoshis: params[:millisatoshis],
            secret: params[:secret],
            message: params[:message],
            seconds: 3,
            preview: true
          )

          expect(request[:service]).to eq(:router)
          expect(request[:method]).to eq(:send_payment_v2)
          expect(request[:params][:timeout_seconds]).to eq(3)

          Contract.expect(
            request, 'ab972e117b8bb7827b12197c0c37efecc3e1c6dbc998839808133f78f43c0223'
          ) do |actual, expected|
            expect(actual.hash).to eq(expected.hash)
            expect(actual.contract).to eq(
              { method: 'Symbol:11..20',
                params: {
                  allow_self_payment: 'Boolean',
                  amp: 'Boolean',
                  amt_msat: 'Integer:0..10',
                  dest: 'String:31..40',
                  dest_custom_records: {
                    34_349_334 => 'String:0..10'
                  },
                  timeout_seconds: 'Integer:0..10'
                },
                service: 'Symbol:0..10' }
            )
          end
        end
      end

      context 'perform' do
        it 'performs' do
          action = described_class.perform(
            through: params[:through],
            public_key: params[:public_key],
            millisatoshis: params[:millisatoshis],
            secret: params[:secret],
            message: params[:message],
            seconds: 5
          ) do |fn, from = :fetch|
            VCR.reel.replay("#{vcr_key}/#{from}", params) { fn.call }
          end

          expect(action.result.class).to eq(Lighstorm::Models::Payment)

          expect(action.result.state).to eq('succeeded')
          expect(action.result.amount.millisatoshis).to eq(1350)
          expect(action.result.fee.millisatoshis).to eq(0)
          expect(action.result.purpose).to eq('self-payment')
          expect(action.result.hops.size).to eq(2)
          expect(action.result.hops.last.amount.millisatoshis).to eq(params[:millisatoshis])

          Contract.expect(
            action.to_h, '7f802535846e6a440d2a27a2e84a569b6ae84e31a4f2797eed31f752bf79b156'
          ) do |actual, expected|
            expect(actual.hash).to eq(expected.hash)
            expect(actual.contract).to eq(expected.contract)
          end
        end
      end
    end
  end
end
