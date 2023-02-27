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
        @amount ||= Satoshis.new(millisatoshis: @data[:amount][:millisatoshis])
      end

      def fee
        @fee ||= Satoshis.new(millisatoshis: @data[:fee][:millisatoshis])
      end

      def channel
        @channel ||= HopChannel.new(@data, @payment)
      end

      def to_h
        {
          hop: hop,
          amount: amount.to_h,
          fee: {
            millisatoshis: fee.millisatoshis,
            parts_per_million: fee.parts_per_million(amount.millisatoshis)
          },
          channel: channel.to_h
        }
      end
    end
  end
end
