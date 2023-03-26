# frozen_string_literal: true

require_relative './concerns/impersonatable'

require_relative './node/myself'
require_relative './node/all'
require_relative './node/find_by_public_key'

module Lighstorm
  module Controllers
    module Node
      extend Impersonatable

      class DSL < Impersonatable::DSL
        def myself
          Myself.model(Myself.data(components), components)
        end

        def all(limit: nil)
          All.model(All.data(components, limit: limit), components)
        end

        def find_by_public_key(public_key)
          FindByPublicKey.model(FindByPublicKey.data(components, public_key), components)
        end

        def adapt(dump: nil, gossip: nil)
          Models::Node.adapt(dump: dump, gossip: gossip)
        end
      end
    end
  end
end
