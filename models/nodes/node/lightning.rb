# frozen_string_literal: true

module Lighstorm
  module Models
    class Lightning
      IMPLEMENTATION = 'lnd'

      attr_reader :implementation, :version

      def initialize(node)
        raise Errors::NotYourNodeError unless node.myself?

        @implementation = IMPLEMENTATION
        @version = node.data[:platform][:lightning][:version]
      end

      def to_h
        {
          implementation: implementation,
          version: version
        }
      end

      def dump
        Marshal.load(
          Marshal.dump({ implementation: implementation, version: version })
        )
      end
    end
  end
end
