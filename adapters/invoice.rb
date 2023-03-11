# frozen_string_literal: true

require 'digest'

require_relative '../ports/dsl/lighstorm/errors'

module Lighstorm
  module Adapter
    class Invoice
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
          payable: 'once',
          created_at: Time.at(grpc[:timestamp]),
          expires_at: Time.at(grpc[:timestamp] + grpc[:expiry]),
          amount: (grpc[:num_msat]).zero? ? nil : { millisatoshis: grpc[:num_msat] },
          description: {
            memo: grpc[:description].empty? ? nil : grpc[:description],
            hash: grpc[:description_hash] == '' ? nil : grpc[:description_hash]
          },
          address: grpc[:payment_addr].unpack1('H*'),
          secret: {
            hash: grpc[:payment_hash]
          }
        }

        adapted[:code] = request_code unless request_code.nil?

        if grpc[:features].key?(30) && grpc[:features][30][:is_required]
          raise "unexpected feature[30] name #{grpc[:features][30][:name]}" if grpc[:features][30][:name] != 'amp'

          adapted[:payable] = 'indefinitely'
        end

        adapted
      end

      def self.lookup_invoice(grpc, at)
        adapted = list_or_lookup_invoice(grpc, at)
        adapted[:_source] = :lookup_invoice
        adapted
      end

      def self.list_invoices(grpc, at)
        adapted = list_or_lookup_invoice(grpc, at)
        adapted[:_source] = :list_invoices
        adapted
      end

      def self.list_or_lookup_invoice(grpc, at)
        raise 'missing at' if at.nil?

        adapted = {
          _key: _key(grpc),
          created_at: Time.at(grpc[:creation_date]),
          expires_at: Time.at(grpc[:creation_date] + grpc[:expiry]),
          settled_at: grpc[:settle_date].nil? || !grpc[:settle_date].positive? ? nil : Time.at(grpc[:settle_date]),
          state: grpc[:state].to_s.downcase,
          code: grpc[:payment_request].empty? ? nil : grpc[:payment_request],
          payable: grpc[:is_amp] == true ? 'indefinitely' : 'once',
          description: {
            memo: grpc[:memo].empty? ? nil : grpc[:memo],
            hash: grpc[:description_hash].empty? ? nil : grpc[:description_hash]
          },
          address: grpc[:payment_addr].unpack1('H*'),
          secret: {
            preimage: grpc[:r_preimage].empty? ? nil : grpc[:r_preimage].unpack1('H*'),
            hash: grpc[:r_hash].empty? ? nil : grpc[:r_hash].unpack1('H*')
          }
        }

        adapted[:amount] = { millisatoshis: grpc[:value_msat] } if grpc[:value_msat] != 0

        adapted[:received] = { millisatoshis: grpc[:amt_paid_msat] } if grpc[:amt_paid_msat] != 0

        if adapted[:state] == 'settled' &&
           adapted[:payable] == 'indefinitely' &&
           adapted[:expires_at] > at
          adapted[:state] = 'open'
        end

        raise 'todo: received with canceled' if !adapted[:received].nil? && adapted[:state] == 'canceled'

        adapted[:payments] = []

        grpc[:htlcs].each do |htlc|
          next unless htlc[:state] == :SETTLED

          payment = {
            amount: { millisatoshis: htlc[:amt_msat] },
            hops: [{ channel: { id: htlc[:chan_id] } }],
            at: Time.at(htlc[:resolve_time])
          }

          if grpc[:is_amp]
            payment[:secret] = {
              preimage: htlc[:amp][:preimage].unpack1('H*'),
              hash: htlc[:amp][:hash].unpack1('H*')
            }
          end

          # https://github.com/satoshisstream/satoshis.stream/blob/main/TLV_registry.md
          if htlc[:custom_records][34_349_334]
            payment[:message] = htlc[:custom_records][34_349_334].dup

            unless payment[:message].force_encoding('UTF-8').valid_encoding?
              payment[:message] = payment[:message].unpack1('H*')

              unless payment[:message].force_encoding('UTF-8').valid_encoding?
                payment[:message] = payment[:message].scrub('?')
              end
            end
          end

          adapted[:payments] << payment
        end

        adapted[:payments] = adapted[:payments].sort_by { |payment| -payment[:at].to_i }

        adapted.delete(:payments) if adapted[:payments].empty?

        adapted
      end

      def self.list_payments(grpc, invoice_decode = nil)
        raise UnexpectedNumberOfHTLCsError, "htlcs: #{grpc[:htlcs].size}" if grpc[:htlcs].size > 1

        data = {
          _key: _key(grpc),
          _source: :list_payments,
          created_at: Time.at(grpc[:creation_date]),
          settled_at: grpc[:settle_date].nil? || !grpc[:settle_date].positive? ? nil : Time.at(grpc[:settle_date]),
          state: nil,
          payable: grpc[:is_amp] == true ? 'indefinitely' : 'once',
          code: grpc[:payment_request].empty? ? nil : grpc[:payment_request],
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

        unless invoice_decode.nil?
          data[:payable] = invoice_decode[:payable]
          data[:expires_at] = invoice_decode[:expires_at]
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
