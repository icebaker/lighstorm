# frozen_string_literal: true

require 'digest'

require_relative 'payment_request'

module Lighstorm
  module Adapter
    class Invoice
      def self.decode_pay_req(grpc, request_code = nil)
        adapted = {
          _source: :decode_pay_req,
          _key: Digest::SHA256.hexdigest(
            [
              grpc[:payment_hash],
              grpc[:num_satoshis],
              grpc[:timestamp],
              grpc[:payment_addr]
            ].join('/')
          ),
          created_at: Time.at(grpc[:timestamp]),
          request: PaymentRequest.decode_pay_req(grpc)
        }

        adapted[:request][:code] = request_code unless request_code.nil?

        adapted
      end

      def self.add_invoice(grpc)
        {
          _source: :add_invoice,
          _key: Digest::SHA256.hexdigest(
            [
              grpc[:r_hash],
              grpc[:add_index],
              grpc[:payment_request],
              grpc[:payment_addr]
            ].join('/')
          ),
          request: PaymentRequest.add_invoice(grpc)
        }
      end

      def self.lookup_invoice(grpc)
        adapted = list_or_lookup(grpc)

        adapted[:_source] = :lookup_invoice
        adapted[:request] = PaymentRequest.lookup_invoice(grpc)

        adapted
      end

      def self.list_invoices(grpc)
        adapted = list_or_lookup(grpc)

        adapted[:_source] = :list_invoices
        adapted[:request] = PaymentRequest.list_invoices(grpc)

        adapted
      end

      def self.list_or_lookup(grpc)
        {
          _key: _key(grpc),
          created_at: Time.at(grpc[:creation_date]),
          settle_at: grpc[:settle_date].nil? || !grpc[:settle_date].positive? ? nil : Time.at(grpc[:settle_date]),
          state: grpc[:state].to_s.downcase
        }
      end

      def self._key(grpc)
        Digest::SHA256.hexdigest(
          [
            grpc[:creation_date],
            grpc[:settle_date],
            grpc[:payment_request],
            grpc[:state]
          ].join('/')
        )
      end
    end
  end
end
