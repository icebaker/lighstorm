# frozen_string_literal: true

require_relative 'invoice'

module Lighstorm
  module Models
    class Transaction
      attr_reader :direction, :at, :message, :_key

      def initialize(data)
        @data = data

        @_key = @data[:_key]
        @at = @data[:at]
        @direction = @data[:direction]
        @message = @data[:message]
      end

      def amount
        @amount ||= Satoshis.new(millisatoshis: @data[:amount][:millisatoshis])
      end

      def invoice
        @invoice ||= @data[:kind] == 'invoice' ? Invoice.new(@data[:data]) : nil
      end

      def to_h
        output = {
          _key: _key,
          at: at,
          direction: direction,
          amount: amount.to_h,
          message: message
        }

        output[:invoice] = invoice.to_h unless invoice.nil?

        output
      end
    end
  end
end
