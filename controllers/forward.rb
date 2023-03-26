# frozen_string_literal: true

require_relative './concerns/impersonatable'

require_relative './forward/all'
require_relative './forward/group_by_channel'

module Lighstorm
  module Controllers
    module Forward
      extend Impersonatable

      class DSL < Impersonatable::DSL
        def all(limit: nil)
          All.model(All.data(components, limit: limit))
        end

        def first
          All.model(All.data(components)).first
        end

        def last
          All.model(All.data(components)).last
        end

        def group_by_channel(direction: :out, hours_ago: nil, limit: nil)
          GroupByChannel.model(
            GroupByChannel.data(components, direction: direction, hours_ago: hours_ago, limit: limit)
          )
        end
      end
    end
  end
end
