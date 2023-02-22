# frozen_string_literal: true

require_relative 'channel_node/policy'
require_relative 'channel_node/accounting'

require_relative '../nodes/node'
require_relative '../errors'

module Lighstorm
  module Models
    class ChannelNode
      def initialize(data, is_mine, transaction)
        @data = data
        @is_mine = is_mine
        @transaction = transaction
      end

      def node
        @node ||= Node.new(@data[:node])
      end

      def policy
        @policy ||= Policy.new(@data[:policy], @transaction)
      end

      def accounting
        raise Errors::NotYourChannelError unless @is_mine

        @accounting ||= @data[:accounting] ? ChannelNodeAccounting.new(@data[:accounting]) : nil
      end

      def to_h
        restult = { node: node.to_h }

        restult[:accounting] = accounting.to_h if @is_mine
        restult[:policy] = policy.to_h if @data[:policy]

        restult
      end
    end
  end
end
