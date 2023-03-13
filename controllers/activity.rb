# frozen_string_literal: true

require_relative './activity/all'

module Lighstorm
  module Controllers
    module Activity
      def self.all(direction: nil, how: nil, limit: nil)
        All.model(All.data(
                    direction: direction,
                    how: how,
                    limit: limit
                  ))
      end
    end
  end
end
