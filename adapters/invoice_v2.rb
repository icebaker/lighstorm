# frozen_string_literal: true

require 'digest'

require_relative '../ports/dsl/lighstorm/errors'

module Lighstorm
  module Adapter
    class InvoiceV2
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
          amount: { millisatoshis: grpc[:num_msat] },
          description: {
            memo: grpc[:description],
            hash: grpc[:description_hash] == '' ? nil : grpc[:description_hash]
          },
          address: grpc[:payment_addr].unpack1('H*'),
          secret: {
            hash: grpc[:payment_hash]
          }
        }

        adapted[:code] = request_code unless request_code.nil?

        adapted
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
          _key: _key(grpc),
          created_at: Time.at(grpc[:creation_date]),
          settled_at: grpc[:settle_date].nil? || !grpc[:settle_date].positive? ? nil : Time.at(grpc[:settle_date]),
          state: grpc[:state].to_s.downcase,
          code: grpc[:payment_request],
          payable: grpc[:is_amp] == true ? :indefinitely : :once,
          amount: { millisatoshis: grpc[:value_msat] },
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

      def self.send_payment_v2(grpc)
        data = {
          _source: :send_payment_v2,
          amount: { millisatoshis: grpc[:payment_route][:total_amt_msat] },
          secret: {
            preimage: grpc[:payment_preimage].unpack1('H*'),
            hash: grpc[:payment_hash].unpack1('H*')
          }
        }

        grpc[:payment_route][:hops].map do |raw_hop|
          if raw_hop[:mpp_record] && raw_hop[:mpp_record][:payment_addr]
            data[:address] = raw_hop[:mpp_record][:payment_addr].unpack1('H*')
          end
        end

        data
      end

      def self.list_payments(grpc)
        raise UnexpectedNumberOfHTLCsError, "htlcs: #{grpc[:htlcs].size}" if grpc[:htlcs].size > 1

        data = {
          _key: _key(grpc),
          _source: :list_payments,
          created_at: Time.at(grpc[:creation_date]),
          settled_at: grpc[:settle_date].nil? || !grpc[:settle_date].positive? ? nil : Time.at(grpc[:settle_date]),
          state: nil,
          payable: grpc[:is_amp] == true ? :indefinitely : :once,
          code: grpc[:payment_request],
          amount: { millisatoshis: grpc[:value_msat] },
          description: {
            memo: grpc[:memo],
            hash: grpc[:description_hash] == '' ? nil : grpc[:description_hash]
          },
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
