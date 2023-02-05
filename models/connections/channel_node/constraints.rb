# frozen_string_literal: true

module Lighstorm
  module Models
    class Constraints
      def initialize(channel, node)
        @channel = channel
        @node = node
      end

      def data
        @data ||= if @node.myself?
                    @channel.data[:list_channels][:channels].first.local_constraints
                  else
                    @channel.data[:list_channels][:channels].first.remote_constraints
                  end
      end

      def to_h
        data.to_h
      end
    end
  end
end
