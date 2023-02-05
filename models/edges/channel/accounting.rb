# frozen_string_literal: true

require_relative '../../satoshis'

module Lighstorm
  module Models
    class ChannelAccounting
      def initialize(channel)
        @channel = channel
      end

      def capacity
        @capacity ||= Satoshis.new(milisatoshis: @channel.data[:get_chan_info].capacity * 1000)
      end

      def sent
        @sent ||= Satoshis.new(milisatoshis: (
                         @channel.data[:list_channels][:channels].first.total_satoshis_sent.to_f * 1000.0
                       ))
      end

      def received
        @received ||= Satoshis.new(milisatoshis: (
                         @channel.data[:list_channels][:channels].first.total_satoshis_received.to_f * 1000.0
                       ))
      end

      def unsettled
        @unsettled ||= Satoshis.new(milisatoshis: (
                         @channel.data[:list_channels][:channels].first.unsettled_balance.to_f * 1000.0
                       ))
      end

      def to_h
        {
          capacity: capacity.to_h,
          sent: sent.to_h,
          received: received.to_h,
          unsettled: unsettled.to_h
        }
      end
    end
  end
end
