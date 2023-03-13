# frozen_string_literal: true

require_relative '../invoice/all'
require_relative '../payment/all'
require_relative '../forward/all'
require_relative '../../models/transaction'

module Lighstorm
  module Controllers
    module Transaction
      module All
        def self.fetch(direction: nil, how: nil, limit: nil)
          transactions = []

          if direction.nil? || direction == 'in'
            Invoice::All.data(spontaneous: true).filter do |invoice|
              !invoice[:payments].nil? && invoice[:payments].size.positive?
            end.each do |invoice|
              transaction_how = invoice[:code].nil? ? 'spontaneously' : 'with-invoice'

              next if !how.nil? && how != transaction_how

              # TODO: Improve performance by reducing invoice fields and removing payments?
              invoice[:payments].each do |payment|
                transactions << {
                  direction: 'in',
                  at: payment[:at],
                  amount: payment[:amount],
                  how: transaction_how,
                  message: payment[:message],
                  data: { invoice: invoice }
                }
              end
            end

            Forward::All.data.each do |forward|
              next if !how.nil? && how != 'forwarding'

              transactions << {
                direction: 'in',
                at: forward[:at],
                amount: forward[:fee],
                how: 'forwarding',
                message: nil,
                data: {}
              }
            end
          end

          if direction.nil? || direction == 'out'
            Payment::All.data(
              fetch: {
                get_node_info: false,
                lookup_invoice: false,
                decode_pay_req: true,
                get_chan_info: false
              }
            )[:data].each do |payment|
              transaction_how = payment[:invoice][:code].nil? ? 'spontaneously' : 'with-invoice'

              next if !how.nil? && how != transaction_how

              # TODO: Improve performance by reducing invoice fields?
              transactions << {
                direction: 'out',
                at: payment[:at],
                amount: payment[:amount],
                how: transaction_how,
                message: payment[:message],
                data: { invoice: payment[:invoice] }
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

        def self.data(direction: nil, how: nil, limit: nil, &vcr)
          raw = if vcr.nil?
                  fetch(direction: direction, how: how, limit: limit)
                else
                  vcr.call(-> { fetch(direction: direction, how: how, limit: limit) })
                end

          transform(raw)
        end

        def self.model(data)
          data.map { |data| Models::Transaction.new(data) }
        end
      end
    end
  end
end
