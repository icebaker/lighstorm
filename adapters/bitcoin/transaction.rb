# frozen_string_literal: true

require 'digest'

module Lighstorm
  module Adapter
    module Bitcoin
      class Transaction
        def self.get_transactions(grpc)
          {
            _source: :get_transactions,
            _key: Digest::SHA256.hexdigest(
              [grpc[:time_stamp], grpc[:tx_hash], grpc[:amount], grpc[:total_fees]].join('/')
            ),
            at: Time.at(grpc[:time_stamp]),
            amount: { millisatoshis: (grpc[:amount] * 1000) + ((grpc[:amount].positive? ? -1 : 1) * (grpc[:total_fees] * 1000)) },
            fee: { millisatoshis: grpc[:total_fees] * 1000 },
            hash: grpc[:tx_hash],
            description: grpc[:label] == '' ? nil : grpc[:label],
            to: { address: { code: grpc[:dest_addresses].first } }
          }
        end

        def self.send_coins(grpc)
          {
            _source: :send_coins,
            _key: Digest::SHA256.hexdigest([grpc[:txid]].join('/')),
            hash: grpc[:txid]
          }
        end
      end
    end
  end
end
