# frozen_string_literal: true

require_relative 'fee'
require_relative 'htlc'

module Lighstorm
  module Models
    class Policy
      def initialize(channel, node)
        @channel = channel
        @node = node
      end

      def data
        return @data if @data

        return if !@channel.data[:get_chan_info] && !@channel.data[:describe_graph]

        key = @channel.data[:get_chan_info] ? :get_chan_info : :describe_graph

        @data ||= if @channel.data[key].node1_pub == @node.public_key
                    @channel.data[key].node1_policy
                  else
                    @channel.data[key].node2_policy
                  end
      end

      def fee
        @fee ||= Fee.new(self, @channel, @node)
      end

      def htlc
        @htlc ||= HTLC.new(self, @channel, @node)
      end

      def to_h
        { fee: fee.to_h, htlc: htlc.to_h }
      end
    end
  end
end
