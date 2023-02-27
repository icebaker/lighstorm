# frozen_string_literal: true

require_relative '../../../../controllers/invoice/actions/create'
require_relative '../../../../models/satoshis'
require_relative '../../../../models/invoice'
require_relative '../../../../ports/dsl/lighstorm/errors'

RSpec.describe Lighstorm::Controllers::Invoice::Create do
  describe 'create invoice' do
    let(:vcr_key) { 'Controllers::Invoice::Create' }
    let(:params) { { millisatoshis: 1_000, description: 'Coffee' } }

    context 'gradual' do
      it 'flows' do
        request = described_class.prepare(
          millisatoshis: params[:millisatoshis], description: params[:description]
        )

        expect(request).to eq(
          { service: :lightning,
            method: :add_invoice,
            params: { memo: params[:description], value_msat: params[:millisatoshis] } }
        )

        response = described_class.dispatch(request) do |grpc|
          VCR.reel.replay("#{vcr_key}/dispatch", params) { grpc.call }
        end

        adapted = described_class.adapt(response)

        expect(adapted).to eq(
          { _source: :add_invoice,
            _key: 'f10abc2e32c031c90e5068622a0aef380a17b6cf286d75fb82d7e61e902dd5be',
            request: { _source: :add_invoice,
                       code: 'lnbc10n1p3l6wdupp5dgstcxacvxcxre2qu26w3lcja8lqlqwruhq5prc0k4uk24xpnvmqdq2gdhkven9v5cqzpgxqyz5vqsp5l4y3uzdmyavxluwsmxnzupkl2qj48s09evq7jfmajagu680jtals9qyyssqcadv32367amqafweqwlwtf0rkrxq4qlnpahxznerkx9nrtdfjgsskrdj607lkaugrsh4wfx3997th9npyd58v7rtdk3zzaw5fgfhk5sq59z4lv',
                       address: '6c51d2cfefb35c2644bde0c9abf2deaa943fd429df498110680737c027342c28',
                       secret: { hash: '6a20bc1bb861b061e540e2b4e8ff12e9fe0f81c3e5c1408f0fb5796554c19b36' } } }
        )

        data = described_class.fetch(adapted) do |fetch|
          VCR.reel.replay("#{vcr_key}/fetch", params) { fetch.call }
        end

        expect(data[:created_at].class).to eq(Time)
        data[:created_at] = data[:created_at].utc.to_s

        expect(data).to eq(
          { _key: 'd76dcb9e5ec73ba443415733c1942937eeb4ad53a741b2c5c948e05b2ad0d50c',
            created_at: '2023-02-27 23:16:12 UTC',
            settle_at: nil,
            state: 'open',
            _source: :lookup_invoice,
            request: { code: 'lnbc10n1p3l6wdupp5dgstcxacvxcxre2qu26w3lcja8lqlqwruhq5prc0k4uk24xpnvmqdq2gdhkven9v5cqzpgxqyz5vqsp5l4y3uzdmyavxluwsmxnzupkl2qj48s09evq7jfmajagu680jtals9qyyssqcadv32367amqafweqwlwtf0rkrxq4qlnpahxznerkx9nrtdfjgsskrdj607lkaugrsh4wfx3997th9npyd58v7rtdk3zzaw5fgfhk5sq59z4lv',
                       amount: { millisatoshis: 1000 },
                       description: { memo: 'Coffee', hash: nil },
                       address: 'e49bbd7d315dc4ea39104271b17fb14a897130de2d54c75cb3f9cb4ad0e58fa2',
                       secret: { preimage: '4d8784e6d4ca0d2a84916f7e483a5bc20a48aff2773a0b73baa182be4760ba17',
                                 hash: '6a20bc1bb861b061e540e2b4e8ff12e9fe0f81c3e5c1408f0fb5796554c19b36' },
                       _source: :lookup_invoice },
            known: true }
        )

        model = described_class.model(data)

        expect(model.to_h).to eq(
          { _key: 'd76dcb9e5ec73ba443415733c1942937eeb4ad53a741b2c5c948e05b2ad0d50c',
            created_at: '2023-02-27 23:16:12 UTC',
            settle_at: nil,
            state: 'open',
            request: { _key: 'ec0271464606009e857a2cc5decc27477e27061fd404174cf3aa191941704325',
                       code: 'lnbc10n1p3l6wdupp5dgstcxacvxcxre2qu26w3lcja8lqlqwruhq5prc0k4uk24xpnvmqdq2gdhkven9v5cqzpgxqyz5vqsp5l4y3uzdmyavxluwsmxnzupkl2qj48s09evq7jfmajagu680jtals9qyyssqcadv32367amqafweqwlwtf0rkrxq4qlnpahxznerkx9nrtdfjgsskrdj607lkaugrsh4wfx3997th9npyd58v7rtdk3zzaw5fgfhk5sq59z4lv',
                       amount: { millisatoshis: 1000 },
                       description: { memo: 'Coffee', hash: nil },
                       secret: { hash: '6a20bc1bb861b061e540e2b4e8ff12e9fe0f81c3e5c1408f0fb5796554c19b36' } } }
        )
      end
    end

    context 'straightforward' do
      context 'preview' do
        it 'previews' do
          request = described_class.perform(
            millisatoshis: 1_000, description: 'Coffee', preview: true
          )

          expect(request).to eq(
            { service: :lightning,
              method: :add_invoice,
              params: { memo: params[:description], value_msat: params[:millisatoshis] } }
          )
        end
      end

      context 'perform' do
        it 'performs' do
          action = described_class.perform(
            millisatoshis: params[:millisatoshis], description: params[:description]
          ) do |fn, from = :fetch|
            VCR.reel.replay("#{vcr_key}/#{from}", params) { fn.call }
          end

          expect(action.result.class).to eq(Lighstorm::Models::Invoice)

          result_to_h = action.result.to_h

          expect(result_to_h[:created_at].class).to eq(Time)
          result_to_h[:created_at] = result_to_h[:created_at].utc.to_s

          expect(result_to_h).to eq(
            { _key: 'd76dcb9e5ec73ba443415733c1942937eeb4ad53a741b2c5c948e05b2ad0d50c',
              created_at: '2023-02-27 23:16:12 UTC',
              settle_at: nil,
              state: 'open',
              request: { _key: 'ec0271464606009e857a2cc5decc27477e27061fd404174cf3aa191941704325',
                         code: 'lnbc10n1p3l6wdupp5dgstcxacvxcxre2qu26w3lcja8lqlqwruhq5prc0k4uk24xpnvmqdq2gdhkven9v5cqzpgxqyz5vqsp5l4y3uzdmyavxluwsmxnzupkl2qj48s09evq7jfmajagu680jtals9qyyssqcadv32367amqafweqwlwtf0rkrxq4qlnpahxznerkx9nrtdfjgsskrdj607lkaugrsh4wfx3997th9npyd58v7rtdk3zzaw5fgfhk5sq59z4lv',
                         amount: { millisatoshis: 1000 },
                         description: { memo: 'Coffee', hash: nil },
                         secret: { hash: '6a20bc1bb861b061e540e2b4e8ff12e9fe0f81c3e5c1408f0fb5796554c19b36' } } }
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
            action.to_h, '373bb94f7c86028b586b8babb36ee6c8efd9c0f65fa56d2692455a25c8664b92'
          ) do |actual, expected|
            expect(actual.hash).to eq(expected.hash)

            expect(actual.contract).to eq(
              { response: {
                  add_index: 'Integer:0..10',
                  payment_addr: 'String:31..40',
                  payment_request: 'String:50+',
                  r_hash: 'String:31..40'
                },
                result: {
                  _key: 'String:50+',
                  created_at: 'Time',
                  request: {
                    _key: 'String:50+',
                    amount: { millisatoshis: 'Integer:0..10' },
                    code: 'String:50+',
                    description: { hash: 'Nil', memo: 'String:0..10' },
                    secret: { hash: 'String:50+' }
                  },
                  settle_at: 'Nil',
                  state: 'String:0..10'
                } }
            )
          end
        end
      end
    end
  end
end
