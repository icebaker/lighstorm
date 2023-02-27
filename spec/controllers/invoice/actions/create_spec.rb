# frozen_string_literal: true

require_relative '../../../../controllers/invoice/actions/create'
require_relative '../../../../models/satoshis'
require_relative '../../../../models/invoice'
require_relative '../../../../ports/dsl/lighstorm/errors'

RSpec.describe Lighstorm::Controllers::Invoice::Create do
  describe 'create invoice' do
    let(:vcr_key) { 'Controllers::Invoice::Create' }
    let(:params) { { milisatoshis: 1_000, description: 'Coffee' } }

    context 'gradual' do
      it 'flows' do
        request = described_class.prepare(
          milisatoshis: params[:milisatoshis], description: params[:description]
        )

        expect(request).to eq(
          { service: :lightning,
            method: :add_invoice,
            params: { memo: params[:description], value_msat: params[:milisatoshis] } }
        )

        response = described_class.dispatch(request) do |grpc|
          VCR.reel.replay("#{vcr_key}/dispatch", params) { grpc.call }
        end

        adapted = described_class.adapt(response)

        expect(adapted).to eq(
          { _source: :add_invoice,
            _key: '25897e871b90d2e633fe3ebaab1628bca0a5590cd784672bc193b04604bbebc2',
            request: { _source: :add_invoice,
                       code: 'lnbc10n1p3l6f7xpp5qymvk7957ssmqmdq06wvx2fgcck9s70ygkpn9snga5y8x47e5cmsdq2gdhkven9v5cqzpgxqyz5vqsp5cmzc02huyakh875kkw75s5c9zynn5pf0n9n70vxhuq86hq3wwf6s9qyyssqjzv4msfp37ryvdtnysaydwwvn6erdzvhk8jwttkf32ats8ue42tx3uxrjka4f9qqamk8ksgvgew2ef74js97k3yxevcn9tyvcgnd4cqqjuxrys',
                       address: 'ccfae18fcafc620c9d19ce4510f6310aa9d50aff29de010cc3b35daae35d41c2',
                       secret: { hash: '0136cb78b4f421b06da07e9cc32928c62c5879e4458332c268ed087357d9a637' } } }
        )

        data = described_class.fetch(adapted) do |fetch|
          VCR.reel.replay("#{vcr_key}/fetch", params) { fetch.call }
        end

        expect(data[:created_at].class).to eq(Time)
        data[:created_at] = data[:created_at].utc.to_s

        expect(data).to eq(
          { _key: '37453ee1b7f70121e413cf98cb103babcb370170468bb4f400c9b3b48b1850f6',
            created_at: '2023-02-27 21:59:34 UTC',
            settle_at: nil,
            state: 'open',
            _source: :lookup_invoice,
            request: { code: 'lnbc10n1p3l6f7xpp5qymvk7957ssmqmdq06wvx2fgcck9s70ygkpn9snga5y8x47e5cmsdq2gdhkven9v5cqzpgxqyz5vqsp5cmzc02huyakh875kkw75s5c9zynn5pf0n9n70vxhuq86hq3wwf6s9qyyssqjzv4msfp37ryvdtnysaydwwvn6erdzvhk8jwttkf32ats8ue42tx3uxrjka4f9qqamk8ksgvgew2ef74js97k3yxevcn9tyvcgnd4cqqjuxrys',
                       amount: { milisatoshis: 1000 },
                       description: { memo: 'Coffee', hash: nil },
                       address: '31b6937881a7f26c7b7b57beeedd6cf4b46b2c7520c032beb230cc8935de9df2',
                       secret: { preimage: 'e00f8ad7457542b8afa7589d9ab6ab48e2058ac5ef6491b2655729638f7927bb',
                                 hash: '0136cb78b4f421b06da07e9cc32928c62c5879e4458332c268ed087357d9a637' },
                       _source: :lookup_invoice },
            known: true }
        )

        model = described_class.model(data)

        expect(model.to_h).to eq(
          { _key: '37453ee1b7f70121e413cf98cb103babcb370170468bb4f400c9b3b48b1850f6',
            created_at: '2023-02-27 21:59:34 UTC',
            settle_at: nil,
            state: 'open',
            request: { _key: 'fb8849b965501c503bc40740246129f231f3fc1b084febf833c8051afb0ed0e9',
                       code: 'lnbc10n1p3l6f7xpp5qymvk7957ssmqmdq06wvx2fgcck9s70ygkpn9snga5y8x47e5cmsdq2gdhkven9v5cqzpgxqyz5vqsp5cmzc02huyakh875kkw75s5c9zynn5pf0n9n70vxhuq86hq3wwf6s9qyyssqjzv4msfp37ryvdtnysaydwwvn6erdzvhk8jwttkf32ats8ue42tx3uxrjka4f9qqamk8ksgvgew2ef74js97k3yxevcn9tyvcgnd4cqqjuxrys',
                       amount: { milisatoshis: 1000 },
                       description: { memo: 'Coffee', hash: nil },
                       secret: { hash: '0136cb78b4f421b06da07e9cc32928c62c5879e4458332c268ed087357d9a637' } } }
        )
      end
    end

    context 'straightforward' do
      context 'preview' do
        it 'previews' do
          request = described_class.perform(
            milisatoshis: 1_000, description: 'Coffee', preview: true
          )

          expect(request).to eq(
            { service: :lightning,
              method: :add_invoice,
              params: { memo: params[:description], value_msat: params[:milisatoshis] } }
          )
        end
      end

      context 'perform' do
        it 'performs' do
          action = described_class.perform(
            milisatoshis: params[:milisatoshis], description: params[:description]
          ) do |fn, from = :fetch|
            VCR.reel.replay("#{vcr_key}/#{from}", params) { fn.call }
          end

          expect(action.result.class).to eq(Lighstorm::Models::Invoice)

          result_to_h = action.result.to_h

          expect(result_to_h[:created_at].class).to eq(Time)
          result_to_h[:created_at] = result_to_h[:created_at].utc.to_s

          expect(result_to_h).to eq(
            { _key: '37453ee1b7f70121e413cf98cb103babcb370170468bb4f400c9b3b48b1850f6',
              created_at: '2023-02-27 21:59:34 UTC',
              settle_at: nil,
              state: 'open',
              request: { _key: 'fb8849b965501c503bc40740246129f231f3fc1b084febf833c8051afb0ed0e9',
                         code: 'lnbc10n1p3l6f7xpp5qymvk7957ssmqmdq06wvx2fgcck9s70ygkpn9snga5y8x47e5cmsdq2gdhkven9v5cqzpgxqyz5vqsp5cmzc02huyakh875kkw75s5c9zynn5pf0n9n70vxhuq86hq3wwf6s9qyyssqjzv4msfp37ryvdtnysaydwwvn6erdzvhk8jwttkf32ats8ue42tx3uxrjka4f9qqamk8ksgvgew2ef74js97k3yxevcn9tyvcgnd4cqqjuxrys',
                         amount: { milisatoshis: 1000 },
                         description: { memo: 'Coffee', hash: nil },
                         secret: { hash: '0136cb78b4f421b06da07e9cc32928c62c5879e4458332c268ed087357d9a637' } } }
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
            action.to_h, '77da43095a93121d7989d59a428db8dbc0bba5f33329739e8bf897f446202bfb'
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
                    amount: { milisatoshis: 'Integer:0..10' },
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
