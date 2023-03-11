# frozen_string_literal: true

require_relative '../invoice/all'
require_relative '../../models/transaction'

module Lighstorm
  module Controllers
    module Transaction
      module All
        def self.fetch(limit: nil)
          transactions = []

          Invoice::All.data(spontaneous: true).filter do |invoice|
            !invoice[:payments].nil? && invoice[:payments].size.positive?
          end.each do |invoice|
            invoice[:payments].each do |payment|
              transactions << {
                direction: 'in',
                at: payment[:at],
                amount: payment[:amount],
                message: payment[:message],
                kind: 'invoice',
                data: invoice
              }
            end
          end

          transactions = transactions.sort_by { |transaction| -transaction[:at].to_i }

          transactions = transactions[0..limit - 1] unless limit.nil?

          { transactions: transactions }
        end

        def self.transform(raw)
          raw[:transactions].map do |transaction|
            transaction[:_key] = SecureRandom.hex
            transaction
          end
        end

        def self.data(limit: nil, &vcr)
          raw = vcr.nil? ? fetch(limit: limit) : vcr.call(-> { fetch(limit: limit) })

          transform(raw)
        end

        def self.model(data)
          data.map { |data| Models::Transaction.new(data) }
        end
      end
    end
  end
end
