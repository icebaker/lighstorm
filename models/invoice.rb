# frozen_string_literal: true

require_relative 'satoshis'
require 'securerandom'

require_relative '../controllers/invoice/actions/create'
require_relative '../controllers/invoice/actions/pay'
require_relative '../controllers/invoice/actions/pay_through_route'

module Lighstorm
  module Models
    class Invoice
      attr_reader :_key, :created_at, :expires_at, :settled_at, :state, :payable, :code

      def initialize(data)
        @data = data

        @_key = data[:_key]
        @created_at = data[:created_at]
        @expires_at = data[:expires_at]
        @settled_at = data[:settled_at]
        @state = data[:state]

        @payable = data[:payable]

        @code = data[:code]
      end

      def payment
        if payable != 'once' || @data[:payments].size > 1
          raise InvoiceMayHaveMultiplePaymentsError, "payable: #{payable}, payments: #{@data[:payments].size.size}"
        end

        @payment ||= payments.first
      end

      def payments
        @payments ||= @data[:payments]&.map { |data| Payment.new(data) }
      end

      def amount
        @amount ||= @data[:amount] ? Satoshis.new(millisatoshis: @data[:amount][:millisatoshis]) : nil
      end

      def received
        @received ||= @data[:received] ? Satoshis.new(millisatoshis: @data[:received][:millisatoshis]) : nil
      end

      def secret
        @secret ||= Secret.new(@data[:secret])
      end

      def description
        @description ||= Struct.new(:data) do
          def memo
            data[:memo]
          end

          def hash
            data[:hash]
          end

          def to_h
            { memo: memo, hash: hash }
          end
        end.new(@data[:description] || {})
      end

      def to_h
        result = {
          _key: _key,
          created_at: created_at,
          expires_at: expires_at,
          settled_at: settled_at,
          payable: payable,
          state: state,
          code: code,
          amount: amount&.to_h,
          received: received&.to_h,
          description: description.to_h,
          secret: secret.to_h,
          payments: payments&.map(&:to_h)
        }
      end

      def pay(
        millisatoshis: nil, message: nil, route: nil,
        times_out_in: { seconds: 5 },
        preview: false
      )
        if route
          Controllers::Invoice::PayThroughRoute.perform(self, route: route, preview: preview)
        else
          Controllers::Invoice::Pay.perform(
            request_code: code,
            millisatoshis: millisatoshis,
            message: message,
            times_out_in: times_out_in,
            preview: preview
          )
        end
      end
    end
  end
end
