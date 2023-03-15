# frozen_string_literal: true

require_relative '../../ports/grpc'
require_relative '../../adapters/transaction'
require_relative '../../models/transaction'

module Lighstorm
  module Controllers
    module Transaction
      module All
        def self.fetch(limit: nil)
          at = Time.now

          transactions = []

          response = Ports::GRPC.lightning.get_transactions

          response.transactions.each do |transaction|
            transactions << transaction.to_h
          end

          transactions = transactions.sort_by { |raw_transaction| -raw_transaction[:time_stamp] }

          transactions = transactions[0..limit - 1] unless limit.nil?

          { at: at, get_transactions: transactions }
        end

        def self.adapt(raw)
          {
            get_transactions: raw[:get_transactions].map do |raw_transaction|
              Lighstorm::Adapter::Transaction.get_transactions(raw_transaction)
            end
          }
        end

        def self.transform(adapted)
          adapted[:get_transactions]
        end

        def self.data(limit: nil, &vcr)
          raw = if vcr.nil?
                  fetch(limit: limit)
                else
                  vcr.call(-> { fetch(limit: limit) })
                end
          adapted = adapt(raw)

          transform(adapted)
        end

        def self.model(data)
          data.map do |transaction_data|
            Lighstorm::Models::Transaction.new(transaction_data)
          end
        end
      end
    end
  end
end
