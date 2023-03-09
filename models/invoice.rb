# frozen_string_literal: true

require_relative 'satoshis'
require 'securerandom'

require_relative '../controllers/invoice/actions/create'
require_relative '../controllers/invoice/actions/pay'
require_relative '../controllers/invoice/actions/pay_through_route'

module Lighstorm
  module Models
    class Invoice
      attr_reader :_key, :created_at, :settled_at, :state, :payable, :code, :address

      def initialize(data)
        @data = data

        @_key = data[:_key]
        @created_at = data[:created_at]
        @settled_at = data[:settled_at]
        @state = data[:state]

        @payable = data[:payable]

        @code = data[:code]
        @address = data[:address]
      end

      def amount
        @amount ||= Satoshis.new(millisatoshis: @data[:amount][:millisatoshis])
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
        {
          _key: _key,
          created_at: created_at,
          settled_at: settled_at,
          payable: payable,
          state: state,
          code: code,
          amount: amount.to_h,
          address: address,
          description: description.to_h,
          secret: secret.to_h
        }
      end

      def pay(seconds: 5, millisatoshis: nil, message: nil, route: nil, preview: false)
        if route
          Controllers::Invoice::PayThroughRoute.perform(self, route: route, preview: preview)
        else
          Controllers::Invoice::Pay.perform(
            request_code: code,
            millisatoshis: millisatoshis,
            message: message,
            seconds: seconds,
            preview: preview
          )
        end
      end
    end
  end
end
