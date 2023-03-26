# frozen_string_literal: true

require_relative './concerns/impersonatable'

require_relative './activity/all'

module Lighstorm
  module Controllers
    module Activity
      extend Impersonatable

      class DSL < Impersonatable::DSL
        def all(direction: nil, layer: nil, how: nil, order: nil, limit: nil)
          All.model(All.data(
                      components,
                      direction: direction,
                      how: how,
                      layer: layer,
                      order: order,
                      limit: limit
                    ))
        end
      end
    end
  end
end
