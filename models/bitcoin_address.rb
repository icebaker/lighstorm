# frozen_string_literal: true

require_relative '../controllers/bitcoin_address/actions/pay'

module Lighstorm
  module Models
    class BitcoinAddress
      attr_reader :_key, :at, :code

      def initialize(data, components)
        @data = data
        @components = components

        @_key = @data[:_key]
        @at = @data[:at]
        @code = @data[:code]
      end

      def pay(
        amount:, fee:,
        description: nil, required_confirmations: 6,
        preview: false, &vcr
      )
        Controllers::BitcoinAddress::Pay.perform(
          @components,
          address_code: code,
          amount: amount, fee: fee, description: description,
          required_confirmations: required_confirmations,
          preview: preview,
          &vcr
        )
      end

      def to_h
        if at || _key
          {
            _key: _key,
            at: at,
            code: code
          }
        else
          { code: code }
        end
      end
    end
  end
end
