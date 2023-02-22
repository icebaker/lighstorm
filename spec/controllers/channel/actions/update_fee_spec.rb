# frozen_string_literal: true

require_relative '../../../../controllers/channel/actions/update_fee'
require_relative '../../../../controllers/channel/mine'
require_relative '../../../../models/edges/channel'
require_relative '../../../../models/satoshis'
require_relative '../../../../models/rate'
require_relative '../../../../ports/dsl/lighstorm/errors'

RSpec.describe Lighstorm::Controllers::Channel::UpdateFee do
  let(:channel) do
    data = Lighstorm::Controllers::Channel::Mine.data do |fetch|
      VCR.replay('Controllers::Channel.mine') do
        data = fetch.call
        data[:list_channels] = [data[:list_channels][0].to_h]
        data
      end
    end

    Lighstorm::Models::Channel.new(data[0])
  end

  describe 'update attributes' do
    it 'updates' do
      policy = channel.myself.policy

      previous = {
        base: policy.fee.base.milisatoshis,
        rate: policy.fee.rate.parts_per_million
      }

      expect(channel.myself.policy.fee.base.milisatoshis).to eq(previous[:base])
      expect(channel.myself.policy.fee.rate.parts_per_million).to eq(previous[:rate])

      expect do
        policy.fee.base = Lighstorm::Models::Satoshis.new(milisatoshis: previous[:base] + 2)
      end.to raise_error(OperationNotAllowedError)

      expect do
        policy.fee.rate = Lighstorm::Models::Rate.new(parts_per_million: previous[:rate] + 3)
      end.to raise_error(OperationNotAllowedError)

      policy.fee.prepare_token!('token-a')

      expect do
        policy.fee.base = {
          value: Lighstorm::Models::Satoshis.new(milisatoshis: previous[:base] + 2),
          token: 'token-x'
        }
      end.to raise_error(OperationNotAllowedError)

      policy.fee.base = {
        value: Lighstorm::Models::Satoshis.new(milisatoshis: previous[:base] + 2),
        token: 'token-a'
      }

      expect do
        policy.fee.rate = {
          value: Lighstorm::Models::Rate.new(parts_per_million: previous[:rate] + 3),
          token: 'token-a'
        }
      end.to raise_error(OperationNotAllowedError)

      policy.fee.prepare_token!('token-b')

      policy.fee.rate = {
        value: Lighstorm::Models::Rate.new(parts_per_million: previous[:rate] + 3),
        token: 'token-b'
      }

      expect(channel.myself.policy.fee.base.milisatoshis).to eq(previous[:base] + 2)
      expect(channel.myself.policy.fee.rate.parts_per_million).to eq(previous[:rate] + 3)
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
        policy.fee.update({ base: { milisatoshis: -5 } }, preview: true)
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
            base_fee_msat: policy.fee.base.milisatoshis,
            time_lock_delta: policy.htlc.blocks.delta.minimum,
            max_htlc_msat: policy.htlc.maximum.milisatoshis,
            min_htlc_msat: policy.htlc.minimum.milisatoshis
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
            base_fee_msat: policy.fee.base.milisatoshis,
            time_lock_delta: policy.htlc.blocks.delta.minimum,
            max_htlc_msat: policy.htlc.maximum.milisatoshis,
            min_htlc_msat: policy.htlc.minimum.milisatoshis
          } }
      )

      params = {
        base: { milisatoshis: policy.fee.base.milisatoshis + 7 }
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
            base_fee_msat: params[:base][:milisatoshis],
            time_lock_delta: policy.htlc.blocks.delta.minimum,
            max_htlc_msat: policy.htlc.maximum.milisatoshis,
            min_htlc_msat: policy.htlc.minimum.milisatoshis
          } }
      )

      params = {
        rate: { parts_per_million: policy.fee.rate.parts_per_million + 5 },
        base: { milisatoshis: policy.fee.base.milisatoshis + 7 }
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
            base_fee_msat: params[:base][:milisatoshis],
            time_lock_delta: policy.htlc.blocks.delta.minimum,
            max_htlc_msat: policy.htlc.maximum.milisatoshis,
            min_htlc_msat: policy.htlc.minimum.milisatoshis
          } }
      )
    end

    it 'fakes the update' do
      policy = channel.myself.policy

      params = {
        rate: { parts_per_million: policy.fee.rate.parts_per_million + 5 },
        base: { milisatoshis: policy.fee.base.milisatoshis + 7 }
      }

      response = policy.fee.update(params, preview: false, fake: true)

      expect(response).to eq(:fake)

      expect(channel.myself.policy.fee.rate.parts_per_million).to eq(
        params[:rate][:parts_per_million]
      )

      expect(channel.myself.policy.fee.base.milisatoshis).to eq(
        params[:base][:milisatoshis]
      )
    end
  end
end
