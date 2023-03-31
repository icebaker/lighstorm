# frozen_string_literal: true

require_relative '../concerns/impersonatable'
require_relative './actions/create'

module Lighstorm
  module Controllers
    module Wallet
      module Bitcoin
        extend Impersonatable

        class DSL < Impersonatable::DSL
          def create(preview: false, &vcr)
            Create.perform(components, preview: preview, &vcr)
          end
        end
      end
    end
  end
end
