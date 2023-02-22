# frozen_string_literal: true

require_relative './forward/all'
require_relative './forward/group_by_channel'

module Lighstorm
  module Controllers
    module Forward
      def self.all(limit: nil)
        All.model(All.data(limit: limit))
      end

      def self.first
        All.model(All.data).first
      end

      def self.last
        All.model(All.data).last
      end

      def self.group_by_channel(direction: :out, hours_ago: nil, limit: nil)
        GroupByChannel.model(
          GroupByChannel.data(direction: direction, hours_ago: hours_ago, limit: limit)
        )
      end
    end
  end
end
