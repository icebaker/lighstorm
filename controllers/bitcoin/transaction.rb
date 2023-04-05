# frozen_string_literal: true

require_relative '../concerns/impersonatable'

require_relative './transaction/all'

module Lighstorm
  module Controller
    module Bitcoin
      module Transaction
        extend Impersonatable

        class DSL < Impersonatable::DSL
          def all(direction: nil, limit: nil)
            All.model(All.data(components, direction: direction, limit: limit))
          end

          def find_by_hash(hash, &vcr)
            All.model(All.data(components, hash: hash, limit: 1, &vcr)).first
          end
        end
      end
    end
  end
end
