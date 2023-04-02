# frozen_string_literal: true

# Circular dependency issue:
# https://stackoverflow.com/questions/8057625/ruby-how-to-require-correctly-to-avoid-circular-dependencies
require_relative '../../../../../models/lightning/edges/channel/hop'
require_relative '../../../../../controllers/lightning/channel/actions/update_fee'
require_relative '../../../../../controllers/lightning/channel/mine'
require_relative '../../../../../models/lightning/edges/channel'
require_relative '../../../../../models/satoshis'
require_relative '../../../../../models/lightning/rate'
require_relative '../../../../../ports/dsl/lighstorm/errors'

RSpec.describe Lighstorm::Controller::Lightning::Channel::UpdateFee do
  let(:vcr_key) { 'Controller::Lightning::Channel::UpdateFee' }

  let(:channel) do
    data = Lighstorm::Controller::Lightning::Channel::Mine.data(
      Lighstorm::Controller::Lightning::Channel.components
    ) do |fetch|
      VCR.reel.replay('Controller::Lightning::Channel.mine/first/fee-update') do
        data = fetch.call
        data[:list_channels] = [data[:list_channels][0].to_h]
        data
      end
    end

    Lighstorm::Model::Lightning::Channel.new(data[0], Lighstorm::Controller::Lightning::Channel.components)
  end

  let(:policy) { channel.myself.policy }

  let(:params) do
    {
      rate: { parts_per_million: policy.fee.rate.parts_per_million + 1 },
      base: { millisatoshis: policy.fee.base.millisatoshis + 1 }
    }
  end

  context 'gradual' do
    it 'flows' do
      request = described_class.prepare(policy.to_h, channel.transaction.to_h, params)

      expect(request).to eq(
        { service: :lightning,
          method: :update_channel_policy,
          params: { chan_point: { funding_txid_str: 'fce72e9b9502033807d69fb92456ced01ab592af4a7cb5a7a7842ba16c47f0c5', output_index: 1 },
                    base_fee_msat: 1001,
                    fee_rate_ppm: 2,
                    time_lock_delta: 40,
                    max_htlc_msat: 247_500_000,
                    min_htlc_msat: 1000 } }
      )

      response = described_class.dispatch(
        Lighstorm::Controller::Lightning::Channel.components,
        request
      ) do |grpc|
        VCR.reel.replay("#{vcr_key}/dispatch", params) { grpc.call }
      end

      expect(response).to eq({ failed_updates: [] })
    end
  end

  describe 'perform' do
    it 'previews the update' do
      policy = channel.myself.policy

      expect(Contract.for(policy.fee.rate.parts_per_million)).to eq('Integer:0..10')

      expect do
        policy.fee.update({ rate: { parts_per_million: -1 } }, preview: true)
      end.to raise_error(NegativeNotAllowedError, "fee rate can't be negative: -1")

      expect do
        policy.fee.update({ base: { millisatoshis: -5 } }, preview: true)
      end.to raise_error(NegativeNotAllowedError, "fee base can't be negative: -5")

      preview = policy.fee.update({}, preview: true)

      expect(preview).to eq(
        { service: :lightning,
          method: :update_channel_policy,
          params: {
            chan_point: {
              funding_txid_str: channel.transaction.funding.id,
              output_index: channel.transaction.funding.index
            },
            fee_rate_ppm: policy.fee.rate.parts_per_million,
            base_fee_msat: policy.fee.base.millisatoshis,
            time_lock_delta: policy.htlc.blocks.delta.minimum,
            max_htlc_msat: policy.htlc.maximum.millisatoshis,
            min_htlc_msat: policy.htlc.minimum.millisatoshis
          } }
      )

      params = {
        rate: { parts_per_million: policy.fee.rate.parts_per_million + 5 }
      }

      preview = policy.fee.update(params, preview: true)

      expect(preview).to eq(
        { service: :lightning,
          method: :update_channel_policy,
          params: {
            chan_point: {
              funding_txid_str: channel.transaction.funding.id,
              output_index: channel.transaction.funding.index
            },
            fee_rate_ppm: params[:rate][:parts_per_million],
            base_fee_msat: policy.fee.base.millisatoshis,
            time_lock_delta: policy.htlc.blocks.delta.minimum,
            max_htlc_msat: policy.htlc.maximum.millisatoshis,
            min_htlc_msat: policy.htlc.minimum.millisatoshis
          } }
      )

      params = {
        base: { millisatoshis: policy.fee.base.millisatoshis + 7 }
      }

      preview = policy.fee.update(params, preview: true)

      expect(preview).to eq(
        { service: :lightning,
          method: :update_channel_policy,
          params: {
            chan_point: {
              funding_txid_str: channel.transaction.funding.id,
              output_index: channel.transaction.funding.index
            },
            fee_rate_ppm: policy.fee.rate.parts_per_million,
            base_fee_msat: params[:base][:millisatoshis],
            time_lock_delta: policy.htlc.blocks.delta.minimum,
            max_htlc_msat: policy.htlc.maximum.millisatoshis,
            min_htlc_msat: policy.htlc.minimum.millisatoshis
          } }
      )

      params = {
        rate: { parts_per_million: policy.fee.rate.parts_per_million + 5 },
        base: { millisatoshis: policy.fee.base.millisatoshis + 7 }
      }

      preview = policy.fee.update(params, preview: true)

      expect(preview).to eq(
        { service: :lightning,
          method: :update_channel_policy,
          params: {
            chan_point: {
              funding_txid_str: channel.transaction.funding.id,
              output_index: channel.transaction.funding.index
            },
            fee_rate_ppm: params[:rate][:parts_per_million],
            base_fee_msat: params[:base][:millisatoshis],
            time_lock_delta: policy.htlc.blocks.delta.minimum,
            max_htlc_msat: policy.htlc.maximum.millisatoshis,
            min_htlc_msat: policy.htlc.minimum.millisatoshis
          } }
      )
    end

    it 'updates' do
      expect(channel.myself.policy.fee.rate.parts_per_million).not_to eq(
        params[:rate][:parts_per_million]
      )

      expect(channel.myself.policy.fee.base.millisatoshis).not_to eq(
        params[:base][:millisatoshis]
      )

      action = policy.fee.update(params) do |grpc|
        VCR.reel.replay("#{vcr_key}/dispatch", params) { grpc.call }
      end

      expect(action.result.to_h).to eq(
        { fee: {
            base: { millisatoshis: 1001 },
            rate: { parts_per_million: 2 }
          },
          htlc: {
            minimum: { millisatoshis: 1000 },
            maximum: { millisatoshis: 247_500_000 },
            blocks: { delta: { minimum: 40 } }
          } }
      )

      expect(action.response.to_h).to eq(
        { failed_updates: [] }
      )

      expect(channel.myself.policy.fee.rate.parts_per_million).to eq(
        params[:rate][:parts_per_million]
      )

      expect(channel.myself.policy.fee.base.millisatoshis).to eq(
        params[:base][:millisatoshis]
      )
    end
  end

  describe 'update attributes' do
    it 'updates' do
      policy = channel.myself.policy

      previous = {
        base: policy.fee.base.millisatoshis,
        rate: policy.fee.rate.parts_per_million
      }

      expect(channel.myself.policy.fee.base.millisatoshis).to eq(previous[:base])
      expect(channel.myself.policy.fee.rate.parts_per_million).to eq(previous[:rate])

      expect do
        policy.fee.base = Lighstorm::Model::Satoshis.new(millisatoshis: previous[:base] + 2)
      end.to raise_error(OperationNotAllowedError)

      expect do
        policy.fee.rate = Lighstorm::Model::Lightning::Rate.new(parts_per_million: previous[:rate] + 3)
      end.to raise_error(OperationNotAllowedError)

      policy.fee.prepare_token!('token-a')

      expect do
        policy.fee.base = {
          value: Lighstorm::Model::Satoshis.new(millisatoshis: previous[:base] + 2),
          token: 'token-x'
        }
      end.to raise_error(OperationNotAllowedError)

      policy.fee.base = {
        value: Lighstorm::Model::Satoshis.new(millisatoshis: previous[:base] + 2),
        token: 'token-a'
      }

      expect do
        policy.fee.rate = {
          value: Lighstorm::Model::Lightning::Rate.new(parts_per_million: previous[:rate] + 3),
          token: 'token-a'
        }
      end.to raise_error(OperationNotAllowedError)

      policy.fee.prepare_token!('token-b')

      policy.fee.rate = {
        value: Lighstorm::Model::Lightning::Rate.new(parts_per_million: previous[:rate] + 3),
        token: 'token-b'
      }

      expect(channel.myself.policy.fee.base.millisatoshis).to eq(previous[:base] + 2)
      expect(channel.myself.policy.fee.rate.parts_per_million).to eq(previous[:rate] + 3)
    end
  end
end
