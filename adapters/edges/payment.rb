# frozen_string_literal: true

require 'digest'
require 'date'

require_relative '../connections/payment_channel'
require_relative 'payment/purpose'

require_relative '../payment_request'

require_relative '../../ports/dsl/lighstorm/errors'

module Lighstorm
  module Adapter
    class Payment
      def self._key(grpc)
        Digest::SHA256.hexdigest(
          [
            grpc[:payment_request],
            grpc[:creation_time_ns],
            grpc[:resolve_time_ns],
            grpc[:status]
          ].join('/')
        )
      end

      def self.list_payments(grpc, node_get_info)
        raise UnexpectedNumberOfHTLCsError, "htlcs: #{grpc[:htlcs].size}" if grpc[:htlcs].size > 1

        data = {
          _source: :list_payments,
          _key: _key(grpc),
          created_at: DateTime.parse(Time.at(grpc[:creation_time_ns] / 1e+9).to_s),
          status: grpc[:status].to_s.downcase,
          fee: { milisatoshis: grpc[:fee_msat] },
          purpose: Purpose.list_payments(grpc, node_get_info),
          request: PaymentRequest.list_payments(grpc),
          hops: grpc[:htlcs].first[:route][:hops].map.with_index do |raw_hop, i|
            hop = PaymentChannel.list_payments(raw_hop, i)
            hop[:channel][:target] = { public_key: raw_hop[:pub_key] }
            hop
          end
        }

        if grpc[:htlcs].first[:resolve_time_ns]
          data[:settled_at] = DateTime.parse(Time.at(grpc[:htlcs].first[:resolve_time_ns] / 1e+9).to_s)
        end

        data
      end
    end
  end
end
