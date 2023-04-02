# frozen_string_literal: true

require_relative './concerns/impersonatable'

require_relative './wallet/balance'

module Lighstorm
  module Controller
    module Wallet
      extend Impersonatable

      class DSL < Impersonatable::DSL
        def balance
          Balance.model(Balance.data(components))
        end
      end
    end
  end
end
