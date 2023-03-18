# frozen_string_literal: true

require_relative './transaction/all'

module Lighstorm
  module Controllers
    module Transaction
      def self.components
        { grpc: Ports::GRPC }
      end

      def self.all(direction: nil, how: nil, limit: nil)
        All.model(All.data(
                    components,
                    direction: direction,
                    how: how,
                    limit: limit
                  ))
      end
    end
  end
end
