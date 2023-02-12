# frozen_string_literal: true

require_relative '../../satoshis'

module Lighstorm
  module Models
    class ChannelNodeAccounting
      def initialize(channel, node)
        @channel = channel
        @node = node
      end

      def balance
        return nil unless @channel.data[:list_channels]

        @balance ||= if @node.myself?
                       Satoshis.new(milisatoshis: (
                         @channel.data[:list_channels][:channels].first.local_balance.to_f * 1000.0
                       ))
                     else
                       Satoshis.new(milisatoshis: (
                         @channel.data[:list_channels][:channels].first.remote_balance.to_f * 1000.0
                       ))
                     end
      end

      def to_h
        { balance: balance.to_h }
      end
    end
  end
end
