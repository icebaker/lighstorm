# frozen_string_literal: true

require_relative '../../controllers/channel'
require_relative '../errors'

require_relative 'node/platform'

module Lighstorm
  module Models
    class Node
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
    end
  end
end
