# frozen_string_literal: true

require_relative '../concerns/impersonatable'
require_relative './request/decode'

module Lighstorm
  module Controller
    module Bitcoin
      module Request
        extend Impersonatable

        class DSL < Impersonatable::DSL
          def create
            raise 'TODO'
            # Create.perform(components, preview: preview, &vcr)
          end

          def decode(uri)
            Decode.model(Decode.data(uri: uri))
          end
        end
      end
    end
  end
end
