# frozen_string_literal: true

require_relative '../../../../controllers/bitcoin_address/actions/pay'
require_relative '../../../../controllers/bitcoin_address'
require_relative '../../../../models/satoshis'
require_relative '../../../../models/transaction'
require_relative '../../../../ports/dsl/lighstorm/errors'
require_relative '../../../../helpers/time_expression'
require_relative '../../../../ports/dsl/lighstorm'

RSpec.describe Lighstorm::Controllers::BitcoinAddress::Pay do
  describe 'pay address' do
    let(:vcr_key) { 'Lighstorm::Controllers::BitcoinAddress::Pay' }
    let(:params) do
      {
        address_code: 'bcrt1qq5gl3thf4ka93eluz0guweek9vmeyqyrck3py2',
        amount: { millisatoshis: 500_000_000 },
        fee: { satoshis_per_vitual_byte: 1 },
        description: 'Wallet Withdrawal',
        required_confirmations: 1
      }
    end

    context 'gradual' do
      it 'flows' do
        request = described_class.prepare(
          address_code: params[:address_code],
          amount: { millisatoshis: 1000 },
          fee: params[:fee],
          description: params[:description],
          required_confirmations: params[:required_confirmations]
        )

        expect(request).to eq(
          { service: :lightning,
            method: :send_coins,
            params: {
              addr: 'bcrt1qq5gl3thf4ka93eluz0guweek9vmeyqyrck3py2',
              amount: 1,
              sat_per_vbyte: 1,
              min_confs: 1,
              label: 'Wallet Withdrawal'
            } }
        )

        response = described_class.dispatch(
          Lighstorm::Controllers::BitcoinAddress.components,
          request
        ) do |grpc|
          VCR.reel.unsafe('I_KNOW_WHAT_I_AM_DOING').replay("#{vcr_key}/dispatch", request) { grpc.call }
        end

        expect do
          described_class.raise_error_if_exists!(request, response)
        end.to raise_error(
          AmountBelowDustLimitError,
          'Amount is too low and considered dust (1 satoshis).'
        )

        request = described_class.prepare(
          address_code: params[:address_code],
          amount: params[:amount],
          fee: params[:fee],
          description: params[:description],
          required_confirmations: params[:required_confirmations]
        )

        expect(request).to eq(
          { service: :lightning,
            method: :send_coins,
            params: {
              addr: 'bcrt1qq5gl3thf4ka93eluz0guweek9vmeyqyrck3py2',
              amount: 500_000,
              sat_per_vbyte: 1,
              min_confs: 1,
              label: 'Wallet Withdrawal'
            } }
        )

        response = described_class.dispatch(
          Lighstorm::Controllers::BitcoinAddress.components,
          request
        ) do |grpc|
          VCR.reel.unsafe('I_KNOW_WHAT_I_AM_DOING').replay("#{vcr_key}/dispatch", request) { grpc.call }
        end

        adapted = described_class.adapt(response)

        expect(adapted).to eq(
          { _source: :send_coins,
            _key: '8f75920132303064d739731aed7b02f577c06c63985a35a1ac51f78d1dbb9597',
            hash: 'f104943c55e968d3216cb82eaa4617eb86cf7050f7d5c20fa736e2a2c9783d55' }
        )

        data = described_class.fetch(
          Lighstorm::Controllers::BitcoinAddress.components,
          adapted
        ) do |fetch|
          VCR.reel.unsafe('I_KNOW_WHAT_I_AM_DOING').replay("#{vcr_key}/fetch", adapted) { fetch.call }
        end

        data_to_h = data.first.clone

        expect(data_to_h[:at].class).to eq(Time)
        data_to_h[:at] = data_to_h[:at].utc.to_s

        expect(data_to_h).to eq(
          { _source: :get_transactions,
            _key: '22ec437cf5f2fa4d24b5aa3f8a644405a789dee8dd8e81301907f3bcb35d3d59',
            at: '2023-04-01 14:29:58 UTC',
            amount: { millisatoshis: -500_000_000 },
            fee: { millisatoshis: 154_000 },
            hash: 'f104943c55e968d3216cb82eaa4617eb86cf7050f7d5c20fa736e2a2c9783d55',
            description: 'Wallet Withdrawal',
            to: { address: { code: params[:address_code] } } }
        )

        model = described_class.model(data).first

        expect(model._key.size).to eq(64)
        expect(model.at.utc.to_s).to eq('2023-04-01 14:29:58 UTC')
        expect(model.hash).to eq(adapted[:hash])
        expect(model.amount.millisatoshis).to eq(-500_000_000)
        expect(model.fee.millisatoshis).to eq(154_000)
        expect(model.description).to eq('Wallet Withdrawal')

        Contract.expect(
          model.to_h, '2f2827afe3acae0d17abdbee49f1006f63a826ccadd06f5bc3fc8e859e6dffad'
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
            Lighstorm::Controllers::BitcoinAddress.components,
            address_code: 'bcrt1qq5gl3thf4ka93eluz0guweek9vmeyqyrck3py2',
            amount: { millisatoshis: 500_000_000 },
            fee: { satoshis_per_vitual_byte: 1 },
            description: 'Wallet Withdrawal',
            required_confirmations: 1,
            preview: true
          )

          expect(request).to eq(
            { service: :lightning,
              method: :send_coins,
              params: {
                addr: 'bcrt1qq5gl3thf4ka93eluz0guweek9vmeyqyrck3py2',
                amount: 500_000,
                sat_per_vbyte: 1,
                min_confs: 1,
                label: 'Wallet Withdrawal'
              } }
          )
        end
      end

      context 'perform' do
        it 'performs' do
          action = described_class.perform(
            Lighstorm::Controllers::BitcoinAddress.components,
            address_code: 'bcrt1qq5gl3thf4ka93eluz0guweek9vmeyqyrck3py2',
            amount: { millisatoshis: 500_000_000 },
            fee: { satoshis_per_vitual_byte: 1 },
            description: 'Wallet Withdrawal',
            required_confirmations: 1
          ) do |fn, from = :fetch|
            VCR.reel.unsafe('I_KNOW_WHAT_I_AM_DOING').replay("#{vcr_key}/#{from}", params) { fn.call }
          end

          expect(action.response).to eq(
            { txid: 'd6529bda37fecf1145f8410de71d62535d27ed5c18e919a91574b089a7b58b58' }
          )

          expect(action.result.class).to eq(Lighstorm::Models::Transaction)

          expect(action.result._key.size).to eq(64)
          expect(action.result.at.utc.to_s).to eq('2023-04-01 14:29:58 UTC')
          expect(action.result.hash).to eq(action.response[:txid])
          expect(action.result.amount.millisatoshis).to eq(-500_000_000)
          expect(action.result.fee.millisatoshis).to eq(154_000)
          expect(action.result.description).to eq('Wallet Withdrawal')

          Contract.expect(
            action.to_h, 'f2a2ecb8b4443ed8511f30cc76b1639552421ec0afdca3b134e0dc8b071e3e2b'
          ) do |actual, expected|
            expect(actual.hash).to eq(expected.hash)
            expect(actual.contract).to eq(expected.contract)
          end
        end
      end
    end
  end
end
