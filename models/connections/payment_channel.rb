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
        @amount ||= Satoshis.new(milisatoshis: @data[:amount][:milisatoshis])
      end

      def fee
        @fee ||= Satoshis.new(milisatoshis: @data[:fee][:milisatoshis])
      end

      def channel
        @channel ||= HopChannel.new(@data, @payment)
      end

      def to_h
        {
          hop: hop,
          amount: amount.to_h,
          fee: {
            milisatoshis: fee.milisatoshis,
            parts_per_million: fee.parts_per_million(amount.milisatoshis)
          },
          channel: channel.to_h
        }
      end
    end
  end
end
