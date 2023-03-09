# frozen_string_literal: true

require 'time'

require_relative '../satoshis'

require_relative '../connections/payment_channel'
require_relative '../nodes/node'
require_relative '../invoice'
require_relative '../secret'

module Lighstorm
  module Models
    class Payment
      attr_reader :_key, :at, :state, :secret, :purpose, :through

      def initialize(data)
        @data = data

        @_key = data[:_key]
        @at = data[:at]
        @state = data[:state]
        @purpose = data[:purpose]
        @through = data[:through]
      end

      def invoice
        @invoice ||= Invoice.new(@data[:invoice])
      end

      def amount
        @amount ||= Satoshis.new(millisatoshis: @data[:amount][:millisatoshis])
      end

      def fee
        @fee ||= Satoshis.new(millisatoshis: @data[:fee][:millisatoshis])
      end

      def secret
        @secret ||= Secret.new(@data[:secret])
      end

      def hops
        return @hops if @hops

        @data[:hops].last[:is_last] = true
        @hops = @data[:hops].map do |hop|
          PaymentChannel.new(hop, self)
        end
      end

      def from
        @from ||= hops.first
      end

      def to
        @to ||= hops.last
      end

      def to_h
        response = {
          _key: _key,
          at: at,
          state: state,
          amount: amount.to_h,
          fee: {
            millisatoshis: fee.millisatoshis,
            parts_per_million: fee.parts_per_million(amount.millisatoshis)
          },
          purpose: purpose,
          invoice: invoice.to_h,
          secret: secret.to_h,
          from: from.to_h,
          to: to.to_h,
          hops: hops.map(&:to_h)
        }
      end
    end
  end
end
