# frozen_string_literal: true

require 'digest'

require_relative '../connections/payment_channel'
require_relative 'payment/purpose'

require_relative '../invoice'

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

      def self.send_payment_v2(grpc, node_myself, invoice_decode)
        adapted = list_payments(grpc, node_myself, invoice_decode)
        adapted[:_source] = :send_payment_v2
        adapted
      end

      def self.list_payments(grpc, node_myself, invoice_decode = nil)
        raise UnexpectedNumberOfHTLCsError, "htlcs: #{grpc[:htlcs].size}" if grpc[:htlcs].size > 1

        data = {
          _source: :list_payments,
          _key: _key(grpc),
          at: Time.at(grpc[:creation_time_ns] / 1e+9),
          state: grpc[:status].to_s.downcase,
          fee: { millisatoshis: grpc[:fee_msat] },
          amount: { millisatoshis: grpc[:value_msat] },
          purpose: Purpose.list_payments(grpc, node_myself),
          invoice: Invoice.list_payments(grpc, invoice_decode)
        }

        data[:secret] = data[:invoice][:secret]

        htlc = grpc[:htlcs].first

        return data if htlc.nil?

        data[:hops] = htlc[:route][:hops].map.with_index do |raw_hop, i|
          hop = PaymentChannel.list_payments(raw_hop, i)
          hop[:channel][:target] = { public_key: raw_hop[:pub_key] }
          hop
        end

        data[:invoice][:settled_at] = Time.at(htlc[:resolve_time_ns] / 1e+9) if htlc[:resolve_time_ns]

        last_hop = htlc[:route][:hops].last

        return data if last_hop.nil?

        # https://github.com/satoshisstream/satoshis.stream/blob/main/TLV_registry.md
        if last_hop[:custom_records][34_349_334]
          data[:message] = last_hop[:custom_records][34_349_334].dup

          unless data[:message].force_encoding('UTF-8').valid_encoding?
            data[:message] = data[:message].unpack1('H*')

            data[:message] = data[:message].scrub('?') unless data[:message].force_encoding('UTF-8').valid_encoding?
          end
        end

        if data[:invoice] && data[:invoice][:code] && !data[:invoice][:code].nil? && !data[:invoice][:code].empty?
          data[:through] = if data[:invoice][:payable] == 'indefinitely'
                             'amp'
                           else
                             'non-amp'
                           end
        else
          data[:through] = last_hop[:mpp_record] ? 'amp' : 'keysend'
        end

        data
      end
    end
  end
end
