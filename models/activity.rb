# frozen_string_literal: true

require_relative 'invoice'
require_relative 'transaction'

module Lighstorm
  module Models
    class Activity
      attr_reader :direction, :at, :message, :layer, :how, :_key

      def initialize(data)
        @data = data

        @_key = @data[:_key]
        @at = @data[:at]
        @direction = @data[:direction]
        @layer = @data[:layer]
        @how = @data[:how]
        @message = @data[:message]
      end

      def amount
        @amount ||= Satoshis.new(millisatoshis: @data[:amount][:millisatoshis])
      end

      def invoice
        @invoice ||= @data[:data][:invoice].nil? ? nil : Invoice.new(@data[:data][:invoice])
      end

      def transaction
        @transaction ||= @data[:data][:transaction].nil? ? nil : Transaction.new(@data[:data][:transaction])
      end

      def to_h
        output = {
          _key: _key,
          at: at,
          direction: direction,
          amount: amount.to_h,
          how: how,
          message: message
        }

        output[:invoice] = invoice.to_h unless invoice.nil?
        output[:transaction] = transaction.to_h unless transaction.nil?

        output
      end
    end
  end
end
