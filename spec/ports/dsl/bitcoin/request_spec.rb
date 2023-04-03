# frozen_string_literal: true

require 'json'

require_relative '../../../../ports/dsl/lighstorm'
require_relative '../../../../ports/dsl/lighstorm/errors'

RSpec.describe Lighstorm::Bitcoin::Request do
  describe 'create invoice' do
    let(:vcr_key) { 'Lighstorm::Bitcoin::Request::Create' }

    context 'defined address' do
      let(:params) do
        { address: { code: '175tWpb8K1S7NmH4Zx6rewF9WQrcZv245W' },
          amount: { millisatoshis: 5_000_000_000_000 },
          description: 'Luke-Jr',
          message: 'Donation for project xyz' }
      end

      context 'perform' do
        it 'performs' do
          action = described_class.create(params) do |fn, from = :fetch|
            VCR.reel.unsafe('I_KNOW_WHAT_I_AM_DOING').replay("#{vcr_key}/#{from}", params) { fn.call }
          end

          expect(action.result.class).to eq(Lighstorm::Model::Bitcoin::Request)

          expect(action.result._key.size).to eq(64)
          expect(action.result.address.code).to eq(params[:address][:code])
          expect(action.result.amount.millisatoshis).to eq(params[:amount][:millisatoshis])
          expect(action.result.description).to eq(params[:description])
          expect(action.result.message).to eq(params[:message])

          expect(action.request).to be_nil
          expect(action.response).to be_nil

          expect(action.to_h.keys).to eq(%i[request response result])

          expect(action.result.to_h).to eq(
            { _key: 'aac0e78574a8e8364dfe73140e69505c3024f6257cb34761a911b2e6ba99417f',
              address: { code: '175tWpb8K1S7NmH4Zx6rewF9WQrcZv245W' },
              uri: 'bitcoin:175tWpb8K1S7NmH4Zx6rewF9WQrcZv245W?amount=50&label=Luke-Jr&message=Donation+for+project+xyz',
              amount: { millisatoshis: 5_000_000_000_000 },
              description: 'Luke-Jr',
              message: 'Donation for project xyz' }
          )
        end
      end
    end

    context 'new address' do
      let(:params) do
        { amount: { millisatoshis: 5_000_000_000_000 },
          description: 'Luke-Jr',
          message: 'Donation for project xyz' }
      end

      context 'perform' do
        it 'performs' do
          action = described_class.create(params) do |fn, from = :fetch|
            VCR.reel.unsafe('I_KNOW_WHAT_I_AM_DOING').replay("#{vcr_key}/#{from}", params) { fn.call }
          end

          expect(action.result.class).to eq(Lighstorm::Model::Bitcoin::Request)

          expect(action.result._key.size).to eq(64)
          expect(action.result.address.code).to eq('bcrt1qfxahhms7c7z5elhnjc4hymvzhwmwmh5slv7jv5')
          expect(action.result.amount.millisatoshis).to eq(params[:amount][:millisatoshis])
          expect(action.result.description).to eq(params[:description])
          expect(action.result.message).to eq(params[:message])

          expect(action.request).to eq(
            { service: :lightning, method: :new_address, params: { type: :WITNESS_PUBKEY_HASH } }
          )
          expect(action.response).to eq({ address: 'bcrt1qfxahhms7c7z5elhnjc4hymvzhwmwmh5slv7jv5' })

          expect(action.to_h.keys).to eq(%i[request response result])

          result_to_h = action.result.to_h

          expect(result_to_h[:address][:created_at].class).to eq(Time)
          result_to_h[:address][:created_at] = result_to_h[:address][:created_at].utc.to_s

          expect(result_to_h).to eq(
            {
              _key: '80a6f24aaaf4c8c36526838853032afd491481085c331322814f35f7ec0d58fd',
              address: {
                _key: 'e2d74b31321c86571493704e79df0db28b239fed35588e6fa45374ef78efd897',
                created_at: '2023-04-02 23:26:12 UTC',
                code: 'bcrt1qfxahhms7c7z5elhnjc4hymvzhwmwmh5slv7jv5'
              },
              uri: 'bitcoin:bcrt1qfxahhms7c7z5elhnjc4hymvzhwmwmh5slv7jv5?amount=50&label=Luke-Jr&message=Donation+for+project+xyz',
              amount: { millisatoshis: 5_000_000_000_000 },
              description: 'Luke-Jr',
              message: 'Donation for project xyz'
            }
          )
        end
      end
    end

    context 'new address only' do
      context 'perform' do
        it 'performs' do
          action = described_class.create do |fn, from = :fetch|
            VCR.reel.unsafe('I_KNOW_WHAT_I_AM_DOING').replay("#{vcr_key}/#{from}") { fn.call }
          end

          expect(action.result.class).to eq(Lighstorm::Model::Bitcoin::Request)

          expect(action.result._key.size).to eq(64)
          expect(action.result.address.code).to eq('bc1qytzke5v5qa4wqzhct37gwnpqs08tuyq9stst5j')
          expect(action.result.amount).to be_nil
          expect(action.result.description).to be_nil
          expect(action.result.message).to be_nil

          expect(action.request).to eq(
            { service: :lightning, method: :new_address, params: { type: :WITNESS_PUBKEY_HASH } }
          )
          expect(action.response).to eq({ address: 'bc1qytzke5v5qa4wqzhct37gwnpqs08tuyq9stst5j' })

          expect(action.to_h.keys).to eq(%i[request response result])

          result_to_h = action.result.to_h

          expect(result_to_h[:address][:created_at].class).to eq(Time)
          result_to_h[:address][:created_at] = result_to_h[:address][:created_at].utc.to_s

          expect(result_to_h).to eq(
            { _key: 'ab3ed16c2e149776c14373a3b4e67541dd530635e3f6460e85d233a36107e0ac',
              address: {
                _key: 'a1dd3ab47f04d1d9ba995ba00f66dd65073170c421de6da0ba9e28ae99bc02ec',
                created_at: '2023-04-03 00:05:15 UTC',
                code: 'bc1qytzke5v5qa4wqzhct37gwnpqs08tuyq9stst5j'
              },
              uri: 'bitcoin:bc1qytzke5v5qa4wqzhct37gwnpqs08tuyq9stst5j' }
          )
        end
      end
    end

    context 'payment' do
      let(:vcr_key) { 'Lighstorm::Bitcoin::Request::Pay' }

      let(:params) do
        { address: { code: 'bcrt1quykkly6egez6dzgfz072h5806p4g2gajm873xn' },
          amount: { millisatoshis: 500_000 },
          description: 'Pay Alice',
          message: 'Hi Alice!' }
      end

      context 'perform' do
        it 'pays' do
          action = described_class.create(params) do |fn, from = :fetch|
            VCR.reel.unsafe('I_KNOW_WHAT_I_AM_DOING').replay("#{vcr_key}/#{from}", params) { fn.call }
          end

          request = action.result

          expect(request.to_h).to eq(
            {
              _key: 'e107e5737d0a2347d6b471fbdd2222163b63e9c7c9a48d169681db9946be21cd',
              address: { code: 'bcrt1quykkly6egez6dzgfz072h5806p4g2gajm873xn' },
              uri: 'bitcoin:bcrt1quykkly6egez6dzgfz072h5806p4g2gajm873xn?amount=5.0e-06&label=Pay+Alice&message=Hi+Alice%21',
              amount: { millisatoshis: 500_000 },
              description: 'Pay Alice',
              message: 'Hi Alice!'
            }
          )

          preview = request.pay(fee: { satoshis_per_vitual_byte: 1 }, preview: true)

          expect(preview).to eq(
            { service: :lightning,
              method: :send_coins,
              params: {
                addr: 'bcrt1quykkly6egez6dzgfz072h5806p4g2gajm873xn',
                amount: 500,
                sat_per_vbyte: 1,
                min_confs: 6,
                label: 'Pay Alice'
              } }
          )

          action = request.pay(fee: { satoshis_per_vitual_byte: 1 }) do |fn, from = :fetch|
            VCR.reel.unsafe('I_KNOW_WHAT_I_AM_DOING').replay("#{vcr_key}/#{from}", params) { fn.call }
          end

          expect(action.request.to_h).to eq(
            {
              service: :lightning,
              method: :send_coins,
              params: {
                addr: 'bcrt1quykkly6egez6dzgfz072h5806p4g2gajm873xn',
                amount: 500,
                sat_per_vbyte: 1,
                min_confs: 6,
                label: 'Pay Alice'
              }
            }
          )

          expect(action.response.to_h).to eq(
            { txid: '5ee90f3d8f3efac87c80797773d696e59986477c9201e5cf15a8abac5f632dd4' }
          )

          transaction = action.result
          transaction_to_h = transaction.to_h

          expect(transaction_to_h[:at].class).to eq(Time)
          transaction_to_h[:at] = transaction_to_h[:at].utc.to_s

          expect(transaction.hash).to eq('5ee90f3d8f3efac87c80797773d696e59986477c9201e5cf15a8abac5f632dd4')
          expect(transaction.amount.millisatoshis).to eq(-500_000)
          expect(transaction.fee.millisatoshis).to eq(154_000)
          expect(transaction.description).to eq('Pay Alice')
          expect(transaction.to.address.code).to eq('bcrt1quykkly6egez6dzgfz072h5806p4g2gajm873xn')

          expect(transaction_to_h).to eq(
            { _key: '0f229ba4a0f18b53d62179da80a8bb351160133873c42323a8692a1cd9f89e5f',
              at: '2023-04-02 23:44:41 UTC',
              hash: '5ee90f3d8f3efac87c80797773d696e59986477c9201e5cf15a8abac5f632dd4',
              amount: { millisatoshis: -500_000 },
              fee: { millisatoshis: 154_000 },
              description: 'Pay Alice',
              to: { address: { code: 'bcrt1quykkly6egez6dzgfz072h5806p4g2gajm873xn' } } }
          )
        end
      end
    end
  end
end
