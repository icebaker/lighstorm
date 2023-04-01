# frozen_string_literal: true

require_relative '../../../../controllers/node'
require_relative '../../../../controllers/node/actions/pay'
require_relative '../../../../models/satoshis'
require_relative '../../../../models/secret'
require_relative '../../../../ports/dsl/lighstorm/errors'

RSpec.describe Lighstorm::Controllers::Node::Pay do
  describe 'send through keysend' do
    let(:vcr_key) { 'Controllers::Node::Pay' }

    let(:payment_params) do
      {
        through: 'keysend',
        public_key: '02d3c80335a8ccb2ed364c06875f32240f36f7edb37d80f8dbe321b4c364b6e997',
        amount: { millisatoshis: 1_000 },
        message: 'hello'
      }
    end

    let(:secret) do
      Lighstorm::Models::Secret.create({}) do |generator|
        VCR.reel.unsafe('I_KNOW_WHAT_I_AM_DOING').replay("#{vcr_key}/secret", payment_params) do
          generator.call
        end
      end.to_h
    end

    let(:params) { payment_params.merge({ secret: secret }) }

    context 'gradual' do
      it 'flows' do
        request = described_class.prepare(
          through: params[:through],
          public_key: params[:public_key],
          amount: params[:amount],
          secret: params[:secret],
          message: params[:message],
          times_out_in: { seconds: 5 }
        )

        expect(request[:service]).to eq(:router)
        expect(request[:method]).to eq(:send_payment_v2)

        Contract.expect(
          request, '0cd672da3b0366bc7b706afc46c73024270a6130c1ada6957ef4444ef4f6b8ef'
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

        response = described_class.dispatch(
          Lighstorm::Controllers::Node.components,
          request
        ) do |grpc|
          VCR.reel.replay("#{vcr_key}/dispatch", params) { grpc.call }
        end

        data = described_class.fetch(
          Lighstorm::Controllers::Node.components
        ) do |fetch|
          VCR.tape.replay("#{vcr_key}/fetch", params) { fetch.call }
        end

        adapted = described_class.adapt(response, data)

        Contract.expect(
          adapted.to_h, '6f2d44fd2bcac4794e16911e1e44f6ea732b7eef95c283bc767f274ad4641b41'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)
        end

        model = described_class.model(adapted, Lighstorm::Controllers::Node.components)

        expect(model.state).to eq('succeeded')
        expect(model.amount.millisatoshis).to eq(1000)
        expect(model.fee.millisatoshis).to eq(0)
        expect(model.purpose).to eq('self-payment')
        expect(model.through).to eq('keysend')
        expect(model.secret.preimage.size).to eq(64)
        expect(model.secret.hash).to eq(params[:secret][:hash])
        expect(model.hops.size).to eq(2)
        expect(model.hops.last.amount.millisatoshis).to eq(params[:amount][:millisatoshis])

        Contract.expect(
          model.to_h, 'f38aa6e599f457c927e2da164e250a7ae199976d9e4d67f6c4313e168e5a23d6'
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
            Lighstorm::Controllers::Node.components,
            through: params[:through],
            public_key: params[:public_key],
            amount: params[:amount],
            secret: params[:secret],
            message: params[:message],
            times_out_in: { seconds: 5 },
            preview: true
          )

          expect(request[:service]).to eq(:router)
          expect(request[:method]).to eq(:send_payment_v2)

          Contract.expect(
            request, '0cd672da3b0366bc7b706afc46c73024270a6130c1ada6957ef4444ef4f6b8ef'
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
            Lighstorm::Controllers::Node.components,
            through: params[:through],
            public_key: params[:public_key],
            amount: params[:amount],
            secret: params[:secret],
            message: params[:message],
            times_out_in: { seconds: 5 }
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
          expect(action.result.hops.last.amount.millisatoshis).to eq(params[:amount][:millisatoshis])

          Contract.expect(
            action.to_h, '8adc399e57e9b2b5956701872a4e3f17225639ff11aa6e2e3d26a583dd17bf6c'
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
        amount: { millisatoshis: 1_350 },
        message: 'hello',
        secret: {
          preimage: 'ad6cd0a63e741f4ad433fa67132d5dda3d317fb761e6352580046a7c333980f0',
          hash: '5be29554bc6feb305b42b11fb0cefb100ef2ba2d87792dd84ec8bf015b3bdcab'
        }
      }
    end

    context 'gradual' do
      it 'flows' do
        request = described_class.prepare(
          through: params[:through],
          public_key: params[:public_key],
          amount: params[:amount],
          secret: params[:secret],
          message: params[:message],
          times_out_in: { seconds: 5 }
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

        response = described_class.dispatch(
          Lighstorm::Controllers::Node.components,
          request
        ) do |grpc|
          VCR.reel.replay("#{vcr_key}/dispatch", params) { grpc.call }
        end

        data = described_class.fetch(
          Lighstorm::Controllers::Node.components
        ) do |fetch|
          VCR.tape.replay("#{vcr_key}/fetch", params) { fetch.call }
        end

        adapted = described_class.adapt(response, data)

        Contract.expect(
          adapted.to_h, '307a6d69693b5aa91eb2d5da3328f3400985671ffc49d95dbed5ef68472f0c09'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)
        end

        model = described_class.model(adapted, Lighstorm::Controllers::Node.components)

        expect(model.state).to eq('succeeded')
        expect(model.amount.millisatoshis).to eq(1350)
        expect(model.fee.millisatoshis).to eq(0)
        expect(model.purpose).to eq('self-payment')
        expect(model.through).to eq('amp')
        expect(model.secret.preimage.size).to eq(64)
        expect(model.secret.hash.size).to eq(64)
        expect(model.hops.size).to eq(2)
        expect(model.hops.last.amount.millisatoshis).to eq(params[:amount][:millisatoshis])

        Contract.expect(
          model.to_h, '217e940c7f583277778e2a7c0ddd81f8fcb67d4295688f787b624e7f47984151'
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
            Lighstorm::Controllers::Node.components,
            through: params[:through],
            public_key: params[:public_key],
            amount: params[:amount],
            secret: params[:secret],
            message: params[:message],
            times_out_in: { seconds: 3 },
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
            Lighstorm::Controllers::Node.components,
            through: params[:through],
            public_key: params[:public_key],
            amount: params[:amount],
            secret: params[:secret],
            message: params[:message],
            times_out_in: { seconds: 5 }
          ) do |fn, from = :fetch|
            VCR.reel.replay("#{vcr_key}/#{from}", params) { fn.call }
          end

          expect(action.result.class).to eq(Lighstorm::Models::Payment)

          expect(action.result.state).to eq('succeeded')
          expect(action.result.amount.millisatoshis).to eq(1350)
          expect(action.result.fee.millisatoshis).to eq(0)
          expect(action.result.purpose).to eq('self-payment')
          expect(action.result.hops.size).to eq(2)
          expect(action.result.hops.last.amount.millisatoshis).to eq(params[:amount][:millisatoshis])

          Contract.expect(
            action.to_h, '0f1bbdaa715d1613655c002a2502c568a82e050ec382a5f5f8fe5a57ff97b894'
          ) do |actual, expected|
            expect(actual.hash).to eq(expected.hash)
            expect(actual.contract).to eq(expected.contract)
          end
        end
      end
    end
  end

  describe 'fee' do
    let(:vcr_key) { 'Controllers::Node::Pay' }
    let(:params) do
      {
        through: 'amp',
        public_key: '02d3c80335a8ccb2ed364c06875f32240f36f7edb37d80f8dbe321b4c364b6e997',
        amount: { millisatoshis: 1_350 },
        fee: { maximum: { millisatoshis: 50 } },
        message: 'hello',
        secret: {
          preimage: 'ad6cd0a63e741f4ad433fa67132d5dda3d317fb761e6352580046a7c333980f0',
          hash: '5be29554bc6feb305b42b11fb0cefb100ef2ba2d87792dd84ec8bf015b3bdcab'
        }
      }
    end

    context 'straightforward' do
      context 'preview' do
        it 'previews' do
          request = described_class.perform(
            Lighstorm::Controllers::Node.components,
            through: params[:through],
            public_key: params[:public_key],
            amount: params[:amount],
            fee: params[:fee],
            secret: params[:secret],
            message: params[:message],
            times_out_in: { seconds: 3 },
            preview: true
          )

          expect(request[:service]).to eq(:router)
          expect(request[:method]).to eq(:send_payment_v2)
          expect(request[:params][:timeout_seconds]).to eq(3)
          expect(request[:params][:fee_limit_msat]).to eq(50)

          Contract.expect(
            request, 'cad3e85e05bd20d1debfa53700c18020066f7aaa2e448dd120102f8b7315ba09'
          ) do |actual, expected|
            expect(actual.hash).to eq(expected.hash)

            expect(actual.contract).to eq(
              { method: 'Symbol:11..20',
                params: { allow_self_payment: 'Boolean',
                          amp: 'Boolean',
                          amt_msat: 'Integer:0..10',
                          dest: 'String:31..40',
                          dest_custom_records: { 34_349_334 => 'String:0..10' },
                          fee_limit_msat: 'Integer:0..10',
                          timeout_seconds: 'Integer:0..10' },
                service: 'Symbol:0..10' }
            )
          end
        end
      end
    end
  end

  context 'errors' do
    describe 'send message through amp' do
      let(:vcr_key) { 'Controllers::Node::Pay' }
      let(:params) do
        {
          through: 'amp',
          public_key: '02d3c80335a8ccb2ed364c06875f32240f36f7edb37d80f8dbe321b4c364b6e997',
          amount: { millisatoshis: 1 },
          message: 'Hello from Lighstorm!',
          secret: {
            preimage: '0c484d9821d1c6bebb0903965db1f437138f39cddcfe6dc2e42c6b5f70502191',
            hash: '2b980e42d4c9535620f9c9cacc35fb7a1466db4d17b20e0a0475be6e9ce7099f'
          }
        }
      end

      context 'gradual' do
        it 'flows' do
          request = described_class.prepare(
            through: params[:through],
            public_key: params[:public_key],
            amount: params[:amount],
            secret: params[:secret],
            message: params[:message],
            times_out_in: { seconds: 5 }
          )

          expect(request[:service]).to eq(:router)
          expect(request[:method]).to eq(:send_payment_v2)

          Contract.expect(
            request, '5f75aafcf7f4307dc16f2ecf8aeb9babb7bb5b34b067bf83759b8c06179a5679'
          ) do |actual, expected|
            expect(actual.hash).to eq(expected.hash)
            expect(actual.contract).to eq(
              { method: 'Symbol:11..20',
                params: { allow_self_payment: 'Boolean',
                          amp: 'Boolean',
                          amt_msat: 'Integer:0..10',
                          dest: 'String:31..40',
                          dest_custom_records: { 34_349_334 => 'String:21..30' },
                          timeout_seconds: 'Integer:0..10' },
                service: 'Symbol:0..10' }
            )
          end

          response = described_class.dispatch(
            Lighstorm::Controllers::Node.components,
            request
          ) do |grpc|
            VCR.reel.replay("#{vcr_key}/dispatch", params) { grpc.call }
          end

          data = described_class.fetch(
            Lighstorm::Controllers::Node.components
          ) do |fetch|
            VCR.tape.replay("#{vcr_key}/fetch", params) { fetch.call }
          end

          adapted = described_class.adapt(response, data)

          Contract.expect(
            adapted.to_h, '75e5f9d616d1dcf7fa49c21aa00fe7e155ed7f55e71d77b543939452f49eca17'
          ) do |actual, expected|
            expect(actual.hash).to eq(expected.hash)
            expect(actual.contract).to eq(expected.contract)
          end

          model = described_class.model(adapted, Lighstorm::Controllers::Node.components)

          expect(model.state).to eq('failed')
          expect(model.amount.millisatoshis).to eq(1)
          expect(model.fee.millisatoshis).to eq(0)
          expect(model.purpose).to eq('unknown')
          expect(model.through).to be_nil
          expect(model.secret.preimage.size).to eq(64)
          expect(model.secret.hash.size).to eq(64)
          expect(model.hops).to be_nil

          Contract.expect(
            model.to_h, '77e2f72deb98fda98eebef3f8984410dd8bfbd896058cbc93918bcf606f24355'
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
              Lighstorm::Controllers::Node.components,
              through: params[:through],
              public_key: params[:public_key],
              amount: params[:amount],
              secret: params[:secret],
              message: params[:message],
              times_out_in: { seconds: 3 },
              preview: true
            )

            expect(request[:service]).to eq(:router)
            expect(request[:method]).to eq(:send_payment_v2)
            expect(request[:params][:timeout_seconds]).to eq(3)

            Contract.expect(
              request, '5f75aafcf7f4307dc16f2ecf8aeb9babb7bb5b34b067bf83759b8c06179a5679'
            ) do |actual, expected|
              expect(actual.hash).to eq(expected.hash)
              expect(actual.contract).to eq(
                { method: 'Symbol:11..20',
                  params: { allow_self_payment: 'Boolean',
                            amp: 'Boolean',
                            amt_msat: 'Integer:0..10',
                            dest: 'String:31..40',
                            dest_custom_records: { 34_349_334 => 'String:21..30' },
                            timeout_seconds: 'Integer:0..10' },
                  service: 'Symbol:0..10' }
              )
            end
          end
        end

        context 'perform' do
          it 'performs' do
            described_class.perform(
              Lighstorm::Controllers::Node.components,
              through: params[:through],
              public_key: params[:public_key],
              amount: params[:amount],
              secret: params[:secret],
              message: params[:message],
              times_out_in: { seconds: 5 }
            ) do |fn, from = :fetch|
              VCR.reel.replay("#{vcr_key}/#{from}", params) { fn.call }
            end
          rescue PaymentError => e
            expect(e.class).to eq(NoRouteFoundError)

            expect(e.result.class).to eq(Lighstorm::Models::Payment)

            expect(e.result.state).to eq('failed')
            expect(e.result.amount.millisatoshis).to eq(1)
            expect(e.result.fee.millisatoshis).to eq(0)
            expect(e.result.purpose).to eq('unknown')
            expect(e.result.hops).to be_nil

            expect(e.response.last[:status]).to eq(:FAILED)
            expect(e.response.last[:failure_reason]).to eq(:FAILURE_REASON_NO_ROUTE)

            Contract.expect(
              e.to_h, 'b72d62240a16051e28fb500e2a187fbf0ceb8cf3adb38be6c72fca6c2ccc794a'
            ) do |actual, expected|
              expect(actual.hash).to eq(expected.hash)
              expect(actual.contract).to eq(expected.contract)
            end
          end
        end
      end
    end
  end
end