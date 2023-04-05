# frozen_string_literal: true

require_relative '../../../ports/grpc'
require_relative '../../../adapters/bitcoin/transaction'
require_relative '../../../models/bitcoin/transaction'

module Lighstorm
  module Controller
    module Bitcoin
      module Transaction
        module All
          def self.fetch(components, direction: nil, hash: nil, limit: nil)
            at = Time.now

            transactions = []

            response = components[:grpc].lightning.get_transactions

            response.transactions.each do |transaction|
              next unless hash.nil? || transaction.tx_hash == hash

              next unless
                direction.nil? ||
                (direction == 'in' && transaction.amount.positive?) ||
                (direction == 'out' && transaction.amount.negative?)

              transactions << transaction.to_h
            end

            transactions = transactions.sort_by { |raw_transaction| -raw_transaction[:time_stamp] }

            transactions = transactions[0..limit - 1] unless limit.nil?

            { at: at, get_transactions: transactions }
          end

          def self.adapt(raw)
            {
              get_transactions: raw[:get_transactions].map do |raw_transaction|
                Adapter::Bitcoin::Transaction.get_transactions(raw_transaction)
              end
            }
          end

          def self.transform(adapted)
            adapted[:get_transactions]
          end

          def self.data(components, hash: nil, direction: nil, limit: nil, &vcr)
            raw = if vcr.nil?
                    fetch(components, hash: hash, direction: direction, limit: limit)
                  else
                    vcr.call(-> { fetch(components, hash: hash, direction: direction, limit: limit) })
                  end

            adapted = adapt(raw)

            transform(adapted)
          end

          def self.model(data)
            data.map do |transaction_data|
              Model::Bitcoin::Transaction.new(transaction_data)
            end
          end
        end
      end
    end
  end
end
