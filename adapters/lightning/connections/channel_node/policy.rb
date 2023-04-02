# frozen_string_literal: true

module Lighstorm
  module Adapter
    module Lightning
      class Policy
        def self.get_chan_info(grpc)
          {
            fee: {
              base: { millisatoshis: grpc[:fee_base_msat] },
              rate: { parts_per_million: grpc[:fee_rate_milli_msat] }
            },
            htlc: {
              minimum: { millisatoshis: grpc[:min_htlc] },
              maximum: { millisatoshis: grpc[:max_htlc_msat] },
              # https://github.com/lightning/bolts/blob/master/02-peer-protocol.md#cltv_expiry_delta-selection
              blocks: {
                delta: {
                  minimum: grpc[:time_lock_delta] # aka cltv_expiry_delta
                }
              }
            }
          }
        end

        def self.subscribe_channel_graph(json)
          result = {
            _source: :subscribe_channel_graph,
            fee: {
              base: { millisatoshis: json['routingPolicy']['feeBaseMsat'].to_i },
              rate: { parts_per_million: json['routingPolicy']['feeRateMilliMsat'].to_i }
            },
            htlc: {
              minimum: { millisatoshis: json['routingPolicy']['minHtlc'].to_i },
              maximum: { millisatoshis: json['routingPolicy']['maxHtlcMsat'].to_i },
              # https://github.com/lightning/bolts/blob/master/02-peer-protocol.md#cltv_expiry_delta-selection
              blocks: {
                delta: {
                  minimum: json['routingPolicy']['timeLockDelta'].to_i # aka cltv_expiry_delta
                }
              }
            }
          }

          policy = json['routingPolicy']

          result[:fee].delete(:base) unless policy.key?('feeBaseMsat') && !policy['feeBaseMsat'].nil?
          result[:fee].delete(:rate) unless policy.key?('feeRateMilliMsat') && !policy['feeRateMilliMsat'].nil?
          result.delete(:fee) if result[:fee].empty?

          result[:htlc].delete(:minimum) unless policy.key?('minHtlc') && !policy['minHtlc'].nil?
          result[:htlc].delete(:maximum) unless policy.key?('maxHtlcMsat') && !policy['maxHtlcMsat'].nil?
          result[:htlc].delete(:blocks) unless policy.key?('timeLockDelta') && !policy['timeLockDelta'].nil?
          result.delete(:htlc) if result[:htlc].empty?

          return nil unless result.key?(:fee) || result.key?(:htlc)

          result
        end
      end
    end
  end
end
