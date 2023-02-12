# frozen_string_literal: true

require_relative '../../satoshis'

module Lighstorm
  module Models
    class ChannelAccounting
      def initialize(channel)
        @channel = channel
      end

      def capacity
        if @channel.data[:get_chan_info]
          @capacity ||= Satoshis.new(milisatoshis: @channel.data[:get_chan_info].capacity * 1000)
        elsif @channel.data[:describe_graph]
          @capacity ||= Satoshis.new(milisatoshis: @channel.data[:describe_graph].capacity * 1000)
        end
      end

      def sent
        return nil unless @channel.data[:list_channels]

        @sent ||= Satoshis.new(milisatoshis: (
                         @channel.data[:list_channels][:channels].first.total_satoshis_sent.to_f * 1000.0
                       ))
      end

      def received
        return nil unless @channel.data[:list_channels]

        @received ||= Satoshis.new(milisatoshis: (
                         @channel.data[:list_channels][:channels].first.total_satoshis_received.to_f * 1000.0
                       ))
      end

      def unsettled
        return nil unless @channel.data[:list_channels]

        @unsettled ||= Satoshis.new(milisatoshis: (
                         @channel.data[:list_channels][:channels].first.unsettled_balance.to_f * 1000.0
                       ))
      end

      def to_h
        if @channel.data[:get_chan_info]
          {
            capacity: capacity.to_h,
            sent: sent.to_h,
            received: received.to_h,
            unsettled: unsettled.to_h
          }
        else
          {
            capacity: capacity.to_h
          }
        end
      end
    end
  end
end
