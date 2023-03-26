# frozen_string_literal: true

require_relative '../nodes/node'
require_relative 'channel_node/policy'

module Lighstorm
  module Adapter
    class ChannelNode
      def self.list_channels(grpc, key)
        data = {
          _source: :list_channels,
          state: grpc[:active] ? 'active' : 'inactive',
          initiator: grpc[:initiator] && key == :local,
          accounting: { balance: { millisatoshis: grpc[:"#{key}_balance"] * 1000 } },
          node: Node.list_channels(grpc, key)
        }

        data.delete(:node) if data[:node].nil?

        data
      end

      def self.get_chan_info(grpc, index)
        data = {
          _source: :get_chan_info,
          node: Node.get_chan_info(grpc, index)
        }

        if grpc[:"node#{index}_policy"]
          data[:state] = grpc[:"node#{index}_policy"][:disabled] ? 'inactive' : 'active'
          data[:policy] = Policy.get_chan_info(grpc[:"node#{index}_policy"])
        end

        data.delete(:node) if data[:node].nil?

        data
      end

      def self.describe_graph(grpc, index)
        data = {
          _source: :describe_graph,
          node: Node.describe_graph_from_channel(grpc, index)
        }

        # TODO: No examples to validate the correctness of this scenario.
        if grpc[:"node#{index}_policy"]
          data[:state] = grpc[:"node#{index}_policy"][:disabled] ? 'inactive' : 'active'
          data[:policy] = Policy.get_chan_info(grpc[:"node#{index}_policy"])
        end

        data.delete(:node) if data[:node].nil?

        data
      end

      def self.subscribe_channel_graph(json)
        data = {
          _source: :subscribe_channel_graph,
          node: {
            public_key: json['advertisingNode']
          },
          policy: Policy.subscribe_channel_graph(json)
        }

        unless json['routingPolicy']['disabled'].nil?
          data[:state] = json['routingPolicy']['disabled'] ? 'inactive' : 'active'
        end

        data.delete(:policy) if data[:policy].nil?

        data
      end
    end
  end
end
