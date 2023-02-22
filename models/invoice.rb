# frozen_string_literal: true

require_relative 'satoshis'
require 'securerandom'

require_relative 'payment_request'

require_relative '../controllers/invoice/actions/create'
require_relative '../controllers/invoice/actions/pay'
require_relative '../controllers/invoice/actions/pay_through_route'

module Lighstorm
  module Models
    class Invoice
      attr_reader :_key, :created_at, :settle_at, :state

      def initialize(data)
        @data = data

        @_key = data[:_key]
        @created_at = data[:created_at]
        @settle_at = data[:settle_at]
        @state = data[:state]
      end

      def request
        @request ||= PaymentRequest.new(@data[:request])
      end

      def to_h
        {
          _key: _key,
          created_at: created_at,
          settle_at: settle_at,
          state: state,
          request: request.to_h
        }
      end

      def pay!(route: nil, preview: false)
        if route
          Controllers::Invoice::PayThroughRoute.perform(self, route: route, preview: preview)
        else
          Controllers::Invoice::Pay.perform(self, preview: preview)
        end
      end
    end
  end
end
