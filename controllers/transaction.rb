# frozen_string_literal: true

require_relative './concerns/impersonatable'

require_relative './transaction/all'

module Lighstorm
  module Controllers
    module Transaction
      extend Impersonatable

      class DSL < Impersonatable::DSL
        def all(direction: nil, how: nil, layer: nil, limit: nil)
          All.model(All.data(
                      components,
                      direction: direction,
                      how: how,
                      layer: layer,
                      limit: limit
                    ))
        end
      end
    end
  end
end
