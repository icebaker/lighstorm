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
              address: {
                code: '175tWpb8K1S7NmH4Zx6rewF9WQrcZv245W',
                specification: { format: 'legacy', code: 'P2PKH', bip: nil }
              },
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
          expect(action.result.address.code).to eq('bcrt1pz7qtzvefmhcha5dgv2h3mz4sla2wsw72jsu43qukasy6d6wm08rqvdhy5l')
          expect(action.result.amount.millisatoshis).to eq(params[:amount][:millisatoshis])
          expect(action.result.description).to eq(params[:description])
          expect(action.result.message).to eq(params[:message])

          expect(action.request).to eq(
            { service: :lightning, method: :new_address, params: { type: :TAPROOT_PUBKEY } }
          )
          expect(action.response).to eq({ address: 'bcrt1pz7qtzvefmhcha5dgv2h3mz4sla2wsw72jsu43qukasy6d6wm08rqvdhy5l' })

          expect(action.to_h.keys).to eq(%i[request response result])

          result_to_h = action.result.to_h

          expect(result_to_h[:address][:created_at].class).to eq(Time)
          result_to_h[:address][:created_at] = result_to_h[:address][:created_at].utc.to_s

          expect(result_to_h).to eq(
            { _key: '7570412f72a96dc838713a97df9c3656096f7ab95964cbf21fffdac779b3bc45',
              address: { _key: 'a85588e14839ad23c3ecf0e4a3e9ef59821af353acfe1dfa9a9891762f001020',
                         created_at: '2023-04-04 12:46:07 UTC',
                         code: 'bcrt1pz7qtzvefmhcha5dgv2h3mz4sla2wsw72jsu43qukasy6d6wm08rqvdhy5l',
                         specification: { format: 'taproot', code: 'P2TR', bip: 341 } },
              uri: 'bitcoin:bcrt1pz7qtzvefmhcha5dgv2h3mz4sla2wsw72jsu43qukasy6d6wm08rqvdhy5l?amount=50&label=Luke-Jr&message=Donation+for+project+xyz',
              amount: { millisatoshis: 5_000_000_000_000 },
              description: 'Luke-Jr',
              message: 'Donation for project xyz' }
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
          expect(action.result.address.code).to eq('bcrt1pjn0awnucxufzd4590mttdawzwnap4ygt0zenu22uqwv997u7u6qsehs4cv')
          expect(action.result.amount).to be_nil
          expect(action.result.description).to be_nil
          expect(action.result.message).to be_nil

          expect(action.request).to eq(
            { service: :lightning, method: :new_address, params: { type: :TAPROOT_PUBKEY } }
          )
          expect(action.response).to eq({ address: 'bcrt1pjn0awnucxufzd4590mttdawzwnap4ygt0zenu22uqwv997u7u6qsehs4cv' })

          expect(action.to_h.keys).to eq(%i[request response result])

          result_to_h = action.result.to_h

          expect(result_to_h[:address][:created_at].class).to eq(Time)
          result_to_h[:address][:created_at] = result_to_h[:address][:created_at].utc.to_s

          expect(result_to_h).to eq(
            { _key: '4a5dcb68f8f429a46896d4d41cf16783ccc960ce432a302e9060abe92ad66589',
              address: { _key: '458d33ffeedd41df17168ec7738a548c704794c5751adfbe665a287fcdf286b5',
                         created_at: '2023-04-04 12:46:51 UTC',
                         code: 'bcrt1pjn0awnucxufzd4590mttdawzwnap4ygt0zenu22uqwv997u7u6qsehs4cv',
                         specification: { format: 'taproot', code: 'P2TR', bip: 341 } },
              uri: 'bitcoin:bcrt1pjn0awnucxufzd4590mttdawzwnap4ygt0zenu22uqwv997u7u6qsehs4cv' }
          )
        end
      end
    end

    context 'nil amount' do
      context 'perform' do
        it 'performs' do
          action = described_class.create(amount: { millisatoshis: nil }) do |fn, from = :fetch|
            VCR.reel.unsafe('I_KNOW_WHAT_I_AM_DOING').replay("#{vcr_key}/#{from}") { fn.call }
          end

          expect(action.result.class).to eq(Lighstorm::Model::Bitcoin::Request)

          expect(action.result._key.size).to eq(64)
          expect(action.result.address.code).to eq('bcrt1pjn0awnucxufzd4590mttdawzwnap4ygt0zenu22uqwv997u7u6qsehs4cv')
          expect(action.result.amount).to be_nil
          expect(action.result.description).to be_nil
          expect(action.result.message).to be_nil

          expect(action.request).to eq(
            { service: :lightning, method: :new_address, params: { type: :TAPROOT_PUBKEY } }
          )
          expect(action.response).to eq({ address: 'bcrt1pjn0awnucxufzd4590mttdawzwnap4ygt0zenu22uqwv997u7u6qsehs4cv' })

          expect(action.to_h.keys).to eq(%i[request response result])

          result_to_h = action.result.to_h

          expect(result_to_h[:address][:created_at].class).to eq(Time)
          result_to_h[:address][:created_at] = result_to_h[:address][:created_at].utc.to_s

          expect(result_to_h).to eq(
            { _key: '4a5dcb68f8f429a46896d4d41cf16783ccc960ce432a302e9060abe92ad66589',
              address: { _key: '458d33ffeedd41df17168ec7738a548c704794c5751adfbe665a287fcdf286b5',
                         created_at: '2023-04-04 12:46:51 UTC',
                         code: 'bcrt1pjn0awnucxufzd4590mttdawzwnap4ygt0zenu22uqwv997u7u6qsehs4cv',
                         specification: { format: 'taproot', code: 'P2TR', bip: 341 } },
              uri: 'bitcoin:bcrt1pjn0awnucxufzd4590mttdawzwnap4ygt0zenu22uqwv997u7u6qsehs4cv' }
          )
        end
      end
    end

    context '1 millisatoshis' do
      let(:params) do
        { amount: { millisatoshis: 1 } }
      end

      context 'perform' do
        it 'performs' do
          action = described_class.create(params) do |fn, from = :fetch|
            VCR.reel.unsafe('I_KNOW_WHAT_I_AM_DOING').replay("#{vcr_key}/#{from}", params) { fn.call }
          end

          expect(action.result.class).to eq(Lighstorm::Model::Bitcoin::Request)

          expect(action.result._key.size).to eq(64)
          expect(action.result.amount.millisatoshis).to eq(params[:amount][:millisatoshis])
          expect(action.result.description).to be_nil
          expect(action.result.message).to be_nil
          expect(action.result.uri).to eq('bitcoin:bc1qkyzf4t2ujjt6p0u3r3zkyxz0tftx77akh64j08?amount=0.00000000001')

          expect(action.to_h.keys).to eq(%i[request response result])

          result_to_h = action.result.to_h

          expect(result_to_h[:address][:created_at].class).to eq(Time)
          result_to_h[:address][:created_at] = result_to_h[:address][:created_at].utc.to_s

          expect(result_to_h).to eq(
            { _key: '10757472930cb58ab5d96566040cb439656d045d8ba49ebe0bb747f29278c136',
              address: { _key: 'e3388f88a94b940c0f559e11b36851757bc57a3602490fb97851046f31ef718f',
                         created_at: '2023-04-03 23:21:59 UTC',
                         code: 'bc1qkyzf4t2ujjt6p0u3r3zkyxz0tftx77akh64j08',
                         specification: { format: 'segwit', code: 'P2WPKH', bip: 173 } },
              uri: 'bitcoin:bc1qkyzf4t2ujjt6p0u3r3zkyxz0tftx77akh64j08?amount=0.00000000001',
              amount: { millisatoshis: 1 } }
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
            { _key: 'e107e5737d0a2347d6b471fbdd2222163b63e9c7c9a48d169681db9946be21cd',
              address: {
                code: 'bcrt1quykkly6egez6dzgfz072h5806p4g2gajm873xn',
                specification: { format: 'segwit', code: 'P2WPKH', bip: 173 }
              },
              uri: 'bitcoin:bcrt1quykkly6egez6dzgfz072h5806p4g2gajm873xn?amount=0.000005&label=Pay+Alice&message=Hi+Alice%21',
              amount: { millisatoshis: 500_000 },
              description: 'Pay Alice',
              message: 'Hi Alice!' }
          )

          preview = request.pay(fee: { maximum: { satoshis_per_vitual_byte: 1 } }, preview: true)

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

          action = request.pay(fee: { maximum: { satoshis_per_vitual_byte: 1 } }) do |fn, from = :fetch|
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
              to: {
                address: {
                  code: 'bcrt1quykkly6egez6dzgfz072h5806p4g2gajm873xn',
                  specification: {
                    format: 'segwit', code: 'P2WPKH', bip: 173
                  }
                }
              } }
          )
        end
      end
    end
  end
end
