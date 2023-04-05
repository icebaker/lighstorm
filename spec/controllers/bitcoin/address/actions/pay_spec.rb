# frozen_string_literal: true

require_relative '../../../../../controllers/bitcoin/address/actions/pay'
require_relative '../../../../../controllers/bitcoin/address'
require_relative '../../../../../models/bitcoin/transaction'
require_relative '../../../../../models/satoshis'
require_relative '../../../../../ports/dsl/lighstorm/errors'

RSpec.describe Lighstorm::Controller::Bitcoin::Address::Pay do
  describe 'pay address' do
    let(:vcr_key) { 'Lighstorm::Controller::Bitcoin::Address::Pay' }
    let(:params) do
      {
        address_code: 'bcrt1qq5gl3thf4ka93eluz0guweek9vmeyqyrck3py2',
        amount: { millisatoshis: 500_000_000 },
        fee: { maximum: { satoshis_per_vitual_byte: 1 } },
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
          Lighstorm::Controller::Bitcoin::Address.components,
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
          Lighstorm::Controller::Bitcoin::Address.components,
          request
        ) do |grpc|
          VCR.reel.unsafe('I_KNOW_WHAT_I_AM_DOING').replay("#{vcr_key}/dispatch", request) { grpc.call }
        end

        adapted = described_class.adapt(response)

        expect(adapted).to eq(
          { _source: :send_coins,
            _key: '0b50611e5456306917a03bae2959632ce116fbaadda10d834373267f7ad857b6',
            hash: '4e6c1177caa744100bd3f7061d2787379e77e3fef695945473cc1e15eeecfed3' }
        )

        data = described_class.fetch(
          Lighstorm::Controller::Bitcoin::Address.components,
          adapted
        ) do |fetch|
          VCR.reel.unsafe('I_KNOW_WHAT_I_AM_DOING').replay("#{vcr_key}/fetch", adapted) { fetch.call }
        end

        data_to_h = data.first.clone

        expect(data_to_h[:at].class).to eq(Time)
        data_to_h[:at] = data_to_h[:at].utc.to_s

        expect(data_to_h).to eq(
          { _source: :get_transactions,
            _key: '2df4be3c037417103533acbe559a24ae1bb33f195be38fb50be7b3a348c3f9aa',
            at: '2023-04-01 23:31:13 UTC',
            amount: { millisatoshis: -500_000_000 },
            fee: { millisatoshis: 154_000 },
            hash: '4e6c1177caa744100bd3f7061d2787379e77e3fef695945473cc1e15eeecfed3',
            description: 'Wallet Withdrawal',
            to: { address: { code: params[:address_code] } } }
        )

        model = described_class.model(data).first

        expect(model._key.size).to eq(64)
        expect(model.at.utc.to_s).to eq('2023-04-01 23:31:13 UTC')
        expect(model.hash).to eq(adapted[:hash])
        expect(model.amount.millisatoshis).to eq(-500_000_000)
        expect(model.fee.millisatoshis).to eq(154_000)
        expect(model.description).to eq('Wallet Withdrawal')

        Contract.expect(
          model.to_h, '5961259e87ed775b8ec88246b467269bb06f19db5bddcf2413d8382957db553e'
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
            Lighstorm::Controller::Bitcoin::Address.components,
            address_code: 'bcrt1qq5gl3thf4ka93eluz0guweek9vmeyqyrck3py2',
            amount: { millisatoshis: 500_000_000 },
            fee: { maximum: { satoshis_per_vitual_byte: 1 } },
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
            Lighstorm::Controller::Bitcoin::Address.components,
            address_code: 'bcrt1qq5gl3thf4ka93eluz0guweek9vmeyqyrck3py2',
            amount: { millisatoshis: 500_000_000 },
            fee: { maximum: { satoshis_per_vitual_byte: 1 } },
            description: 'Wallet Withdrawal',
            required_confirmations: 1
          ) do |fn, from = :fetch|
            VCR.reel.unsafe('I_KNOW_WHAT_I_AM_DOING').replay("#{vcr_key}/#{from}", params) { fn.call }
          end

          expect(action.response).to eq(
            { txid: '9068b5e021e2259fe9461a4e8108d3b8dc4494d72ff2684bda20f0630c1623d9' }
          )

          expect(action.result.class).to eq(Lighstorm::Model::Bitcoin::Transaction)

          expect(action.result._key.size).to eq(64)
          expect(action.result.at.utc.to_s).to eq('2023-04-03 22:14:12 UTC')
          expect(action.result.hash).to eq(action.response[:txid])
          expect(action.result.amount.millisatoshis).to eq(-500_000_000)
          expect(action.result.fee.millisatoshis).to eq(154_000)
          expect(action.result.description).to eq('Wallet Withdrawal')

          Contract.expect(
            action.to_h, '890b67ce4c074ee9aaa9a67b78ad5ff2275ce17e3493ce7000f6986fcb6810cc'
          ) do |actual, expected|
            expect(actual.hash).to eq(expected.hash)
            expect(actual.contract).to eq(expected.contract)
          end
        end
      end
    end
  end
end