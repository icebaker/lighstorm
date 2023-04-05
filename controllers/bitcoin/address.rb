# frozen_string_literal: true

require_relative '../concerns/impersonatable'
require_relative './address/actions/create'

module Lighstorm
  module Controller
    module Bitcoin
      module Address
        extend Impersonatable

        class DSL < Impersonatable::DSL
          def new(code:)
            Model::Bitcoin::Address.new({ code: code }, components)
          end

          def create(format: 'taproot', preview: false, &vcr)
            Create.perform(components, format: format, preview: preview, &vcr)
          end
        end
      end
    end
  end
end
