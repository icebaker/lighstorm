# frozen_string_literal: true

require_relative '../../controllers/node/actions/apply_gossip'
require_relative '../../controllers/node/actions/pay'
require_relative '../../controllers/channel'
require_relative '../../adapters/nodes/node'
require_relative '../concerns/protectable'
require_relative '../errors'

require_relative 'node/platform'

module Lighstorm
  module Models
    class Node
      include Protectable

      attr_reader :data, :_key, :alias, :public_key, :color

      def initialize(data)
        @data = data

        @_key = @data[:_key]
        @alias = @data[:alias]
        @public_key = @data[:public_key]
        @color = @data[:color]
      end

      def myself?
        @data[:myself] == true
      end

      def platform
        @platform ||= Platform.new(self)
      end

      def channels
        raise Errors::NotYourNodeError unless myself?

        Controllers::Channel.mine
      end

      def to_h
        result = {
          _key: _key,
          public_key: public_key
        }

        result[:alias] = @alias unless self.alias.nil?
        result[:color] = @color unless color.nil?

        result[:platform] = platform.to_h if @data[:platform]

        result
      end

      def dump
        result = Marshal.load(Marshal.dump(@data))

        result[:platform] = platform.dump if @data[:platform]

        result
      end

      def alias=(value)
        protect!(value)

        @alias = value[:value]

        @data[:alias] = @alias

        self.alias
      end

      def color=(value)
        protect!(value)

        @color = value[:value]

        @data[:color] = @color

        color
      end

      def self.adapt(gossip: nil, dump: nil)
        raise TooManyArgumentsError, 'you need to pass gossip: or dump:, not both' if !gossip.nil? && !dump.nil?

        raise ArgumentError, 'missing gossip: or dump:' if gossip.nil? && dump.nil?

        if !gossip.nil?
          new(Adapter::Node.subscribe_channel_graph(gossip))
        elsif !dump.nil?
          new(dump)
        end
      end

      def apply!(gossip:)
        Controllers::Node::ApplyGossip.perform(
          self, gossip
        )
      end

      def send_message(
        message, amount:, secret: nil,
        times_out_in: { seconds: 5 }, through: 'amp',
        preview: false
      )
        pay(
          message: message,
          amount: amount,
          secret: secret,
          times_out_in: times_out_in,
          through: through,
          preview: preview
        )
      end

      def pay(
        amount:, message: nil, secret: nil,
        times_out_in: { seconds: 5 }, through: 'amp',
        preview: false
      )
        Controllers::Node::Pay.perform(
          public_key: public_key,
          amount: amount,
          through: through,
          secret: secret,
          message: message,
          times_out_in: times_out_in,
          preview: preview
        )
      end
    end
  end
end
