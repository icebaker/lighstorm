# frozen_string_literal: true

module Lighstorm
  module Adapter
    module Lightning
      class Purpose
        def self.send_payment_v2(grpc, node_get_info)
          return 'unknown' if grpc[:payment_route][:hops].empty?

          return 'self-payment' if self_payment?(grpc[:payment_route][:hops])
          return 'peer-to-peer' if peer_to_peer?(grpc[:payment_route][:hops])
          return 'rebalance' if rebalance?(grpc[:payment_route][:hops], node_get_info)

          'payment'
        end

        def self.list_payments(grpc, node_get_info)
          return 'unknown' if grpc[:htlcs].empty?

          return 'self-payment' if self_payment?(grpc[:htlcs].last[:route][:hops])
          return 'peer-to-peer' if peer_to_peer?(grpc[:htlcs].last[:route][:hops])
          return 'rebalance' if rebalance?(grpc[:htlcs].last[:route][:hops], node_get_info)

          'payment'
        end

        def self.self_payment?(hops)
          hops.size == 2 && hops[0][:chan_id] == hops[1][:chan_id]
        end

        def self.peer_to_peer?(hops)
          hops.size == 1
        end

        def self.rebalance?(hops, node_get_info)
          return false if hops.size <= 2

          destination_public_key = hops.last[:pub_key]

          node_get_info[:identity_pubkey] == destination_public_key
        end
      end
    end
  end
end
