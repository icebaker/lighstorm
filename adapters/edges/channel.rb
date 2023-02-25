# frozen_string_literal: true

require 'date'
require 'digest'

require_relative '../connections/channel_node'

module Lighstorm
  module Adapter
    class Channel
      def self._key(id, state)
        Digest::SHA256.hexdigest(
          [id, state].join('/')
        )
      end

      def self.list_channels(grpc, at)
        {
          _source: :list_channels,
          _key: _key(grpc[:chan_id], grpc[:active] ? 'active' : 'inactive'),
          # Standard JSON don't support BigInt, so, a String is safer.
          id: grpc[:chan_id].to_s,
          transaction: {
            funding: {
              id: grpc[:channel_point].split(':').first,
              index: grpc[:channel_point].split(':').last.to_i
            }
          },
          opened_at: DateTime.parse((at - grpc[:lifetime]).to_s),
          up_at: DateTime.parse((at - grpc[:uptime]).to_s),
          state: grpc[:active] ? 'active' : 'inactive',
          exposure: grpc[:private] ? 'private' : 'public',
          accounting: {
            capacity: { milisatoshis: grpc[:capacity] * 1000 },
            sent: { milisatoshis: grpc[:total_satoshis_sent] * 1000 },
            received: { milisatoshis: grpc[:total_satoshis_received] * 1000 },
            unsettled: { milisatoshis: grpc[:unsettled_balance] * 1000 }
          },
          partners: [
            ChannelNode.list_channels(grpc, :local),
            ChannelNode.list_channels(grpc, :remote)
          ]
        }
      end

      def self.get_chan_info(grpc)
        {
          _source: :get_chan_info,
          _key: _key(grpc[:channel_id], nil),
          # Standard JSON don't support BigInt, so, a String is safer.
          id: grpc[:channel_id].to_s,
          accounting: {
            capacity: { milisatoshis: grpc[:capacity] * 1000 }
          },
          partners: [
            ChannelNode.get_chan_info(grpc, 1),
            ChannelNode.get_chan_info(grpc, 2)
          ]
        }
      end

      def self.describe_graph(grpc)
        {
          _source: :describe_graph,
          _key: _key(grpc[:channel_id], nil),
          # Standard JSON don't support BigInt, so, a String is safer.
          id: grpc[:channel_id].to_s,
          exposure: 'public',
          accounting: {
            capacity: { milisatoshis: grpc[:capacity] * 1000 }
          },
          partners: [
            ChannelNode.describe_graph(grpc, 1),
            ChannelNode.describe_graph(grpc, 2)
          ]
        }
      end

      def self.subscribe_channel_graph(json)
        {
          _source: :subscribe_channel_graph,
          _key: _key(json['chanId'], nil),
          id: json['chanId'],
          accounting: {
            capacity: { milisatoshis: json['capacity'].to_i * 1000 }
          },
          partners: [
            ChannelNode.subscribe_channel_graph(json),
            { node: {
              public_key: json['connectingNode']
            } }
          ]
        }
      end
    end
  end
end
