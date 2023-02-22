# frozen_string_literal: true

require 'digest'

module Lighstorm
  module Adapter
    class Node
      def self._key(public_key)
        Digest::SHA256.hexdigest(
          [public_key].join('/')
        )
      end

      def self.get_chan_info(grpc, index)
        {
          _source: :get_chan_info,
          _key: _key(grpc[:"node#{index}_pub"]),
          public_key: grpc[:"node#{index}_pub"]
        }
      end

      def self.list_channels(grpc, key)
        {
          _source: :list_channels,
          _key: _key(key == :remote ? grpc[:remote_pubkey] : nil),
          public_key: key == :remote ? grpc[:remote_pubkey] : nil
        }
      end

      def self.get_info(grpc)
        {
          _source: :get_info,
          _key: _key(grpc[:identity_pubkey]),
          public_key: grpc[:identity_pubkey],
          alias: grpc[:alias],
          color: grpc[:color],
          platform: {
            blockchain: grpc[:chains][0][:chain],
            network: grpc[:chains][0][:network],
            lightning: {
              implementation: 'lnd',
              version: grpc[:version]
            }
          }
        }
      end

      def self.get_node_info(grpc)
        {
          _source: :get_node_info,
          _key: _key(grpc[:node][:pub_key]),
          public_key: grpc[:node][:pub_key],
          alias: grpc[:node][:alias],
          color: grpc[:node][:color]
        }
      end

      def self.describe_graph(grpc)
        {
          _source: :describe_graph,
          _key: _key(grpc[:pub_key]),
          public_key: grpc[:pub_key],
          alias: grpc[:alias],
          color: grpc[:color]
        }
      end

      def self.describe_graph_from_channel(grpc, index)
        {
          _source: :describe_graph,
          _key: _key(grpc[:"node#{index}_pub"]),
          public_key: grpc[:"node#{index}_pub"]
        }
      end
    end
  end
end
