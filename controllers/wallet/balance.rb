# frozen_string_literal: true

require_relative '../../adapters/wallet'
require_relative '../../models/wallet/balance'

module Lighstorm
  module Controller
    module Wallet
      module Balance
        def self.fetch(components)
          {
            at: Time.now,
            wallet_balance: components[:grpc].lightning.wallet_balance.to_h,
            channel_balance: components[:grpc].lightning.channel_balance.to_h
          }
        end

        def self.adapt(raw)
          Adapter::Wallet.balance(raw)
        end

        def self.data(components, &vcr)
          raw = vcr.nil? ? fetch(components) : vcr.call(-> { fetch(components) })

          adapt(raw)
        end

        def self.model(data)
          Model::Wallet::Balance.new(data)
        end
      end
    end
  end
end
