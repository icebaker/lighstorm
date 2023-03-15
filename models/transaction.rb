# frozen_string_literal: true

require_relative './satoshis'

module Lighstorm
  module Models
    class Transaction
      attr_reader :_key, :at, :hash, :label

      def initialize(data)
        @data = data

        @_key = @data[:_key]
        @at = @data[:at]
        @hash = @data[:hash]
        @label = @data[:label]
      end

      def amount
        @amount ||= Satoshis.new(millisatoshis: @data[:amount][:millisatoshis])
      end

      def fee
        @fee ||= Satoshis.new(millisatoshis: @data[:fee][:millisatoshis])
      end

      def to_h
        {
          _key: _key,
          at: at,
          hash: hash,
          amount: amount.to_h,
          fee: fee.to_h,
          label: label
        }
      end
    end
  end
end
