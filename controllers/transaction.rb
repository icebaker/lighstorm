# frozen_string_literal: true

require_relative './concerns/impersonatable'

require_relative './transaction/all'

module Lighstorm
  module Controllers
    module Transaction
      extend Impersonatable

      class DSL < Impersonatable::DSL
        def all(limit: nil)
          All.model(All.data(components, limit: limit))
        end

        def find_by_hash(hash, &vcr)
          All.model(All.data(components, hash: hash, limit: 1, &vcr)).first
        end
      end
    end
  end
end
