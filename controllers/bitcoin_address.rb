# frozen_string_literal: true

require_relative './concerns/impersonatable'
require_relative './bitcoin_address/actions/create'

module Lighstorm
  module Controllers
    module BitcoinAddress
      extend Impersonatable

      class DSL < Impersonatable::DSL
        def new(code:)
          Models::BitcoinAddress.new({ code: code }, components)
        end

        def create(preview: false, &vcr)
          Create.perform(components, preview: preview, &vcr)
        end
      end
    end
  end
end
