# frozen_string_literal: true

require_relative 'channel_node/policy'
require_relative 'channel_node/accounting'

require_relative '../nodes/node'
require_relative '../errors'

module Lighstorm
  module Models
    class ChannelNode
      include Protectable

      attr_reader :state

      def initialize(data, components, is_mine, transaction)
        @data = data
        @components = components
        @state = data[:state]
        @initiator = data[:initiator]
        @is_mine = is_mine
        @transaction = transaction
      end

      def active?
        state == 'active'
      end

      def initiator?
        @initiator
      end

      def node
        @node ||= Node.new(@data[:node], @components)
      end

      def policy
        @policy ||= Policy.new(@data[:policy], @components, @transaction)
      end

      def accounting
        raise Errors::NotYourChannelError unless @is_mine

        @accounting ||= @data[:accounting] ? ChannelNodeAccounting.new(@data[:accounting]) : nil
      end

      def to_h
        restult = {
          state: state,
          initiator: @initiator,
          node: node.to_h
        }

        restult[:accounting] = accounting.to_h if @is_mine
        restult[:policy] = policy.to_h if @data[:policy]

        restult
      end

      def dump
        result = Marshal.load(Marshal.dump(@data)).merge(
          {
            node: node.dump,
            policy: policy.dump
          }
        )

        result[:accounting] = accounting.dump if @is_mine
        result.delete(:policy) if result[:policy].nil?

        result
      end

      def state=(value)
        protect!(value)

        @state = value[:value]
        @data[:state] = @state

        state
      end
    end
  end
end
