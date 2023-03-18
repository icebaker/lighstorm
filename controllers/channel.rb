# frozen_string_literal: true

require_relative './concerns/impersonatable'

require_relative './channel/mine'
require_relative './channel/all'
require_relative './channel/find_by_id'

module Lighstorm
  module Controllers
    module Channel
      extend Impersonatable

      class DSL < Impersonatable::DSL
        def mine(injected_components = nil)
          if injected_components.nil?
            Mine.model(Mine.data(components), components)
          else
            Mine.model(Mine.data(injected_components), injected_components)
          end
        end

        def all(limit: nil)
          All.model(All.data(components, limit: limit), components)
        end

        def find_by_id(id, injected_components = nil)
          if injected_components.nil?
            FindById.model(FindById.data(components, id), components)
          else
            FindById.model(FindById.data(injected_components, id), injected_components)
          end
        end

        def adapt(dump: nil, gossip: nil)
          Models::Channel.adapt(dump: dump, gossip: gossip)
        end
      end
    end
  end
end
