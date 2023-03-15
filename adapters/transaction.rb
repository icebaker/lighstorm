# frozen_string_literal: true

require 'digest'

module Lighstorm
  module Adapter
    class Transaction
      def self.get_transactions(grpc)
        {
          _source: :get_transactions,
          _key: Digest::SHA256.hexdigest(
            [grpc[:time_stamp], grpc[:tx_hash], grpc[:amount], grpc[:total_fees]].join('/')
          ),
          at: Time.at(grpc[:time_stamp]),
          amount: { millisatoshis: grpc[:amount] * 1000 },
          fee: { millisatoshis: grpc[:total_fees] * 1000 },
          hash: grpc[:tx_hash],
          label: grpc[:label]
        }
      end
    end
  end
end
