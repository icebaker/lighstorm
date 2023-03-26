# frozen_string_literal: true

require 'digest'

module Lighstorm
  module Adapter
    class Wallet
      def self.balance(raw)
        {
          _key: Digest::SHA256.hexdigest(
            [
              raw[:at],
              channel_balance(raw[:channel_balance])[:amount],
              wallet_balance(raw[:wallet_balance])[:amount]
            ].join('/')
          ),
          at: raw[:at],
          bitcoin: wallet_balance(raw[:wallet_balance])[:amount],
          lightning: channel_balance(raw[:channel_balance])[:amount],
          total: { millisatoshis: (
            wallet_balance(raw[:wallet_balance])[:amount][:millisatoshis] +
            channel_balance(raw[:channel_balance])[:amount][:millisatoshis]
          ) }
        }
      end

      def self.wallet_balance(grpc)
        {
          _source: :wallet_balance,
          amount: { millisatoshis: grpc[:total_balance] * 1000 }
        }
      end

      def self.channel_balance(grpc)
        {
          _source: :channel_balance,
          amount: { millisatoshis: grpc[:local_balance][:msat] }
        }
      end
    end
  end
end
