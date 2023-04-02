# frozen_string_literal: true

require_relative '../lightning/invoice'
require_relative '../bitcoin/transaction'

module Lighstorm
  module Model
    module Wallet
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
          @invoice ||= @data[:data][:invoice].nil? ? nil : Lightning::Invoice.new(@data[:data][:invoice], nil)
        end

        def transaction
          @transaction ||= @data[:data][:transaction].nil? ? nil : Bitcoin::Transaction.new(@data[:data][:transaction])
        end

        def to_h
          output = {
            _key: _key,
            at: at,
            direction: direction,
            layer: layer,
            how: how,
            amount: amount.to_h,
            message: message
          }

          output[:invoice] = invoice.to_h unless invoice.nil?
          output[:transaction] = transaction.to_h unless transaction.nil?

          output
        end
      end
    end
  end
end
