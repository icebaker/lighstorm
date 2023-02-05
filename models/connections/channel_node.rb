# frozen_string_literal: true

require_relative 'channel_node/constraints'
require_relative 'channel_node/policy'
require_relative 'channel_node/accounting'

module Lighstorm
  module Models
    class ChannelNode
      KIND = :connection

      attr_reader :node

      def initialize(channel, node)
        @channel = channel
        @node = node
      end

      def policy
        @policy ||= Policy.new(@channel, @node)
      end

      def constraints
        @constraints ||= Constraints.new(@channel, @node)
      end

      def accounting
        @accounting ||= ChannelNodeAccounting.new(@channel, @node)
      end

      def to_h
        {
          accounting: accounting.to_h,
          node: @node.to_h,
          policy: policy.to_h
          # constraints: constraints.to_h
        }
      end
    end
  end
end
