# frozen_string_literal: true

require_relative '../edges/channel'

module Lighstorm
  module Models
    class ForwardChannel
      def initialize(data)
        @data = data
      end

      def amount
        @amount ||= Satoshis.new(millisatoshis: @data[:amount][:millisatoshis])
      end

      def channel
        @channel ||= Channel.new(@data[:channel])
      end

      def to_h
        {
          amount: amount.to_h,
          channel: channel.to_h
        }
      end
    end
  end
end
