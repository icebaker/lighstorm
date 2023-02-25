# frozen_string_literal: true

require 'digest'

require_relative 'payment_request'

module Lighstorm
  module Adapter
    class Invoice
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
          settle_at: Time.at(grpc[:settle_date]),
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
