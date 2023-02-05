# frozen_string_literal: true

require_relative 'fee'

module Lighstorm
  module Models
    class Policy
      def initialize(channel, node)
        @channel = channel
        @node = node
      end

      def data
        @data ||= if @channel.data[:get_chan_info].node1_pub == @node.public_key
                    @channel.data[:get_chan_info].node1_policy
                  else
                    @channel.data[:get_chan_info].node2_policy
                  end
      end

      def fees
        @fees ||= Fee.new(self, @channel, @node)
      end

      def to_h
        { fee: fees.to_h }
      end
    end
  end
end
