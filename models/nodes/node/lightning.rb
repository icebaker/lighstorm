# frozen_string_literal: true

require_relative '../../../components/lnd'

module Lighstorm
  module Models
    class Lightning
      IMPLEMENTATION = 'lnd'

      def initialize(platform, node)
        raise 'cannot provide platform details for a node that is not yours' unless node.myself?

        @platform = platform
      end

      def version
        @version ||= @platform.data[:get_info].version
      end

      def raw
        { get_info: @data[:get_info].to_h }
      end

      def implementation
        @implementation ||= IMPLEMENTATION
      end

      def to_h
        {
          implementation: implementation,
          version: version
        }
      end
    end
  end
end
