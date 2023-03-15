# frozen_string_literal: true

require_relative './transaction/all'

module Lighstorm
  module Controllers
    module Transaction
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
