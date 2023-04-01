# frozen_string_literal: true

require_relative '../concerns/impersonatable'
require_relative './actions/send'

module Lighstorm
  module Controllers
    module Wallet
      module Bitcoin
        extend Impersonatable

        class DSL < Impersonatable::DSL
          def send(preview: false, &vcr)
            # Balance.model(Balance.data(components))
          end
        end
      end
    end
  end
end
