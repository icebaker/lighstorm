# frozen_string_literal: true

require_relative '../edges/channel/hop'
require_relative '../nodes/node'

module Lighstorm
  module Models
    class PaymentChannel
      attr_reader :hop

      def initialize(data, payment)
        @data = data

        @hop = data[:hop]
        @payment = payment
      end

      def first?
        @hop == 1
      end

      def last?
        @data[:is_last] == true
      end

      def amount
        @amount ||= @data[:amount] ? Satoshis.new(millisatoshis: @data[:amount][:millisatoshis]) : nil
      end

      def fee
        @fee ||= @data[:fee] ? Satoshis.new(millisatoshis: @data[:fee][:millisatoshis]) : nil
      end

      def channel
        @channel ||= HopChannel.new(@data, @payment)
      end

      def to_h
        result = {
          hop: hop,
          channel: channel.to_h
        }

        result[:amount] = amount.to_h if amount
        if fee
          result[:fee] = {
            millisatoshis: fee.millisatoshis,
            parts_per_million: fee.parts_per_million(amount.millisatoshis)
          }
        end

        result
      end
    end
  end
end
