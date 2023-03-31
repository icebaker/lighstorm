# frozen_string_literal: true

require_relative './concerns/impersonatable'

require_relative './wallet/balance'
require_relative './wallet/bitcoin'

module Lighstorm
  module Controllers
    module Wallet
      Bitcoin = Bitcoin

      extend Impersonatable

      class DSL < Impersonatable::DSL
        def balance
          Balance.model(Balance.data(components))
        end
      end
    end
  end
end
