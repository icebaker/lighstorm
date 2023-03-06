# frozen_string_literal: true

require 'json'

require_relative '../../../ports/dsl/lighstorm'
require_relative '../../../ports/dsl/lighstorm/errors'

RSpec.describe Lighstorm::Invoice do
  describe 'create invoice' do
    let(:vcr_key) { 'Controllers::Invoice::Create' }
    let(:params) { { millisatoshis: 1_000, description: 'Coffee' } }

    context 'straightforward' do
      context 'preview' do
        it 'previews' do
          request = described_class.create(
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
          action = described_class.create(
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

  describe 'decode' do
    let(:vcr_key) { 'Controllers::Invoice::Decode' }
    let(:params) do
      { request_code: 'lnbc20n1pjq2ywjpp5qy4mms9xqe7h3uhgtct7gt4qxmx56630xwdgenup9x73ggcsk7lsdqggaexzur9cqzpgxqyz5vqsp5je8mp8d49gvq0hj37jkp6y7vapvsgc6nflehhwpqw0yznclzuuqq9qyyssqt38umwt9wdd09dgejd68v88jnwezr9j2y87pv3yr5yglw77kqk6hn3jv6ue573m003n06r2yfa8yzzyh8zr3rgkkwqg9sf4arv490eqps7h0k9' }
    end

    it 'decodes' do
      invoice = described_class.decode(params[:request_code]) do |fn, _from = :fetch|
        VCR.reel.replay(vcr_key.to_s, params) { fn.call }
      end

      expect(invoice.class).to eq(Lighstorm::Models::Invoice)

      invoice_to_h = invoice.to_h

      Contract.expect(
        invoice.to_h, 'a30a93197a2598e42ad10013abb5b8808bd816af30b71c6b780de4c58c22976a'
      ) do |actual, expected|
        expect(actual.hash).to eq(expected.hash)
        expect(actual.contract).to eq(
          { _key: 'String:50+',
            created_at: 'Time',
            request: {
              _key: 'String:50+',
              amount: { millisatoshis: 'Integer:0..10' },
              code: 'String:50+',
              description: { hash: 'Nil', memo: 'String:0..10' },
              secret: { hash: 'String:50+' }
            },
            settle_at: 'Nil',
            state: 'Nil' }
        )
      end
    end
  end
end
