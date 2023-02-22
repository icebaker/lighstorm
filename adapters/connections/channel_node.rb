# frozen_string_literal: true

require_relative '../nodes/node'

module Lighstorm
  module Adapter
    class ChannelNode
      def self.list_channels(grpc, key)
        {
          _source: :list_channels,
          accounting: { balance: { milisatoshis: grpc[:"#{key}_balance"] * 1000 } },
          node: Node.list_channels(grpc, key)
        }
      end

      def self.get_chan_info(grpc, index)
        data = {
          _source: :get_chan_info,
          node: Node.get_chan_info(grpc, index)
        }

        if grpc[:"node#{index}_policy"]
          data[:policy] = {
            fee: {
              base: { milisatoshis: grpc[:"node#{index}_policy"][:fee_base_msat] },
              rate: { parts_per_million: grpc[:"node#{index}_policy"][:fee_rate_milli_msat] }
            },
            htlc: {
              minimum: { milisatoshis: grpc[:"node#{index}_policy"][:min_htlc] },
              maximum: { milisatoshis: grpc[:"node#{index}_policy"][:max_htlc_msat] },
              # https://github.com/lightning/bolts/blob/master/02-peer-protocol.md#cltv_expiry_delta-selection
              blocks: {
                delta: {
                  minimum: grpc[:"node#{index}_policy"][:time_lock_delta] # aka cltv_expiry_delta
                }
              }
            }
          }
        end

        data
      end

      def self.describe_graph(grpc, index)
        {
          _source: :describe_graph,
          node: Node.describe_graph_from_channel(grpc, index)
        }
      end
    end
  end
end
