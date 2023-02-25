# frozen_string_literal: true

module Lighstorm
  module Adapter
    class Purpose
      def self.list_payments(grpc, node_get_info)
        return 'self-payment' if self_payment?(grpc)
        return 'peer-to-peer' if peer_to_peer?(grpc)
        return 'rebalance' if rebalance?(grpc, node_get_info)

        'payment'
      end

      def self.self_payment?(grpc)
        grpc[:htlcs].first[:route][:hops].size == 2 &&
          grpc[:htlcs].first[:route][:hops][0][:chan_id] == grpc[:htlcs].first[:route][:hops][1][:chan_id]
      end

      def self.peer_to_peer?(grpc)
        grpc[:htlcs].first[:route][:hops].size == 1
      end

      def self.rebalance?(grpc, node_get_info)
        return false if grpc[:htlcs].first[:route][:hops].size <= 2

        destination_public_key = grpc[:htlcs].first[:route][:hops].last[:pub_key]

        node_get_info[:identity_pubkey] == destination_public_key
      end
    end
  end
end
