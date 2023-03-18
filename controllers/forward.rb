# frozen_string_literal: true

require_relative './forward/all'
require_relative './forward/group_by_channel'

module Lighstorm
  module Controllers
    module Forward
      def self.components
        { grpc: Ports::GRPC }
      end

      def self.all(limit: nil)
        All.model(All.data(components, limit: limit))
      end

      def self.first
        All.model(All.data(components)).first
      end

      def self.last
        All.model(All.data(components)).last
      end

      def self.group_by_channel(direction: :out, hours_ago: nil, limit: nil)
        GroupByChannel.model(
          GroupByChannel.data(components, direction: direction, hours_ago: hours_ago, limit: limit)
        )
      end
    end
  end
end
