# frozen_string_literal: true

require 'digest'

require_relative '../ports/dsl/lighstorm/errors'

module Lighstorm
  module Adapter
    class PaymentRequest
      def self.add_invoice(grpc)
        {
          _source: :add_invoice,
          code: grpc[:payment_request],
          address: grpc[:payment_addr].unpack1('H*'),
          secret: {
            hash: grpc[:r_hash].unpack1('H*')
          }
        }
      end

      def self.decode_pay_req(grpc)
        {
          _source: :decode_pay_req,
          amount: { milisatoshis: grpc[:num_msat] },
          description: {
            memo: grpc[:description],
            hash: grpc[:description_hash] == '' ? nil : grpc[:description_hash]
          },
          address: grpc[:payment_addr].unpack1('H*'),
          secret: {
            hash: grpc[:payment_hash]
          }
        }
      end

      def self.lookup_invoice(grpc)
        adapted = list_or_lookup_invoice(grpc)
        adapted[:_source] = :lookup_invoice
        adapted
      end

      def self.list_invoices(grpc)
        adapted = list_or_lookup_invoice(grpc)
        adapted[:_source] = :list_invoices
        adapted
      end

      def self.list_or_lookup_invoice(grpc)
        {
          code: grpc[:payment_request],
          amount: { milisatoshis: grpc[:value_msat] },
          description: {
            memo: grpc[:memo],
            hash: grpc[:description_hash] == '' ? nil : grpc[:description_hash]
          },
          address: grpc[:payment_addr].unpack1('H*'),
          secret: {
            preimage: grpc[:r_preimage].unpack1('H*'),
            hash: grpc[:r_hash].unpack1('H*')
          }
        }
      end

      def self.list_payments(grpc)
        raise UnexpectedNumberOfHTLCsError, "htlcs: #{grpc[:htlcs].size}" if grpc[:htlcs].size > 1

        data = {
          _source: :list_payments,
          code: grpc[:payment_request],
          amount: { milisatoshis: grpc[:value_msat] },
          secret: {
            preimage: grpc[:payment_preimage],
            hash: grpc[:payment_hash]
          }
        }

        grpc[:htlcs].first[:route][:hops].map do |raw_hop|
          if raw_hop[:mpp_record] && raw_hop[:mpp_record][:payment_addr]
            data[:address] = raw_hop[:mpp_record][:payment_addr].unpack1('H*')
          end
        end

        data
      end
    end
  end
end
