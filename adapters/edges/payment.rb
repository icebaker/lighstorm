# frozen_string_literal: true

require 'digest'

require_relative '../connections/payment_channel'
require_relative 'payment/purpose'

require_relative '../invoice_v2'

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

      def self.send_payment_v2(grpc, node_get_info, _context = nil)
        list_payments(grpc, node_get_info)

        # if context != :node_send

        # data = {
        #   _source: :list_payments,
        #   _key: _key(grpc),
        #   state: grpc[:payment_error].empty? ? 'succeeded' : 'error',
        #   fee: { millisatoshis: grpc[:payment_route][:total_fees_msat] },
        #   amount: { millisatoshis: grpc[:payment_route][:total_amt_msat] },
        #   purpose: Purpose.send_payment_v2(grpc, node_get_info),
        #   invoice: InvoiceV2.send_payment_v2(grpc),
        #   hops: grpc[:payment_route][:hops].map.with_index do |raw_hop, i|
        #     hop = PaymentChannel.list_payments(raw_hop, i)
        #     hop[:channel][:target] = { public_key: raw_hop[:pub_key] }
        #     hop
        #   end
        # }

        # data[:secret] = data[:invoice][:secret]

        # data
      end

      def self.list_payments(grpc, node_get_info)
        raise UnexpectedNumberOfHTLCsError, "htlcs: #{grpc[:htlcs].size}" if grpc[:htlcs].size > 1

        data = {
          _source: :list_payments,
          _key: _key(grpc),
          at: Time.at(grpc[:creation_time_ns] / 1e+9),
          state: grpc[:status].to_s.downcase,
          fee: { millisatoshis: grpc[:fee_msat] },
          amount: { millisatoshis: grpc[:value_msat] },
          purpose: Purpose.list_payments(grpc, node_get_info),
          invoice: InvoiceV2.list_payments(grpc),
          hops: grpc[:htlcs].first[:route][:hops].map.with_index do |raw_hop, i|
            hop = PaymentChannel.list_payments(raw_hop, i)
            hop[:channel][:target] = { public_key: raw_hop[:pub_key] }
            hop
          end
        }

        data[:secret] = data[:invoice][:secret]

        if grpc[:htlcs].first[:resolve_time_ns]
          data[:invoice][:settled_at] = Time.at(grpc[:htlcs].first[:resolve_time_ns] / 1e+9)
        end

        data[:through] = if grpc[:htlcs].first[:route][:hops].last[:mpp_record]
                           'amp'
                         else
                           'keysend'
                         end

        data
      end
    end
  end
end
