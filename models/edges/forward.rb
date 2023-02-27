# frozen_string_literal: true

require 'time'

require_relative '../satoshis'

require_relative '../connections/forward_channel'
require_relative 'groups/channel_forwards'

module Lighstorm
  module Models
    class Forward
      attr_reader :_key, :at

      def initialize(data)
        @data = data

        @_key = data[:_key]
        @at = data[:at]
      end

      def fee
        @fee ||= Satoshis.new(millisatoshis: @data[:fee][:millisatoshis])
      end

      def in
        @in ||= ForwardChannel.new(@data[:in])
      end

      def out
        @out ||= ForwardChannel.new(@data[:out])
      end

      def to_h
        {
          _key: _key,
          at: at,
          fee: {
            millisatoshis: fee.millisatoshis,
            parts_per_million: fee.parts_per_million(self.in.amount.millisatoshis)
          },
          in: self.in.to_h,
          out: out.to_h
        }
      end
    end
  end
end
