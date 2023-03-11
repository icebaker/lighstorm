# frozen_string_literal: true

require_relative '../../ports/grpc'
require_relative '../../adapters/invoice'
require_relative '../../models/invoice'

module Lighstorm
  module Controllers
    module Invoice
      module All
        def self.fetch(limit: nil, spontaneous: false)
          at = Time.now

          last_offset = 0

          invoices = []

          loop do
            response = Ports::GRPC.lightning.list_invoices(
              index_offset: last_offset,
              num_max_invoices: 10
            )

            response.invoices.each do |invoice|
              invoices << invoice.to_h if spontaneous || !invoice.payment_request.empty?
            end

            # TODO: How to optimize this?
            # break if !limit.nil? && invoices.size >= limit

            break if last_offset == response.last_index_offset || last_offset > response.last_index_offset

            last_offset = response.last_index_offset
          end

          invoices = invoices.sort_by { |raw_invoice| -raw_invoice[:creation_date] }

          invoices = invoices[0..limit - 1] unless limit.nil?

          { at: at, list_invoices: invoices }
        end

        def self.adapt(raw)
          raise 'missing at' if raw[:at].nil?

          {
            list_invoices: raw[:list_invoices].map do |raw_invoice|
              Lighstorm::Adapter::Invoice.list_invoices(raw_invoice, raw[:at])
            end
          }
        end

        def self.transform(adapted)
          adapted[:list_invoices].map do |invoice|
            invoice[:known] = true
            invoice
          end
        end

        def self.data(limit: nil, spontaneous: false, &vcr)
          raw = if vcr.nil?
                  fetch(limit: limit, spontaneous: spontaneous)
                else
                  vcr.call(-> { fetch(limit: limit, spontaneous: spontaneous) })
                end

          adapted = adapt(raw)

          transform(adapted)
        end

        def self.model(data)
          data.map do |node_data|
            Lighstorm::Models::Invoice.new(node_data)
          end
        end
      end
    end
  end
end
