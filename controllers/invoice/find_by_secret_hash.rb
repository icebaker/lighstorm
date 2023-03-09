# frozen_string_literal: true

require_relative '../../ports/grpc'
require_relative '../../adapters/invoice_v2'
require_relative '../../models/invoice'

module Lighstorm
  module Controllers
    module Invoice
      module FindBySecretHash
        def self.fetch(secret_hash)
          {
            lookup_invoice: Ports::GRPC.lightning.lookup_invoice(r_hash_str: secret_hash).to_h
          }
        end

        def self.adapt(raw)
          {
            lookup_invoice: Lighstorm::Adapter::InvoiceV2.lookup_invoice(raw[:lookup_invoice])
          }
        end

        def self.transform(adapted)
          adapted[:lookup_invoice][:known] = true
          adapted[:lookup_invoice]
        end

        def self.data(secret_hash, &vcr)
          raw = vcr.nil? ? fetch(secret_hash) : vcr.call(-> { fetch(secret_hash) })

          adapted = adapt(raw)

          transform(adapted)
        end

        def self.model(data)
          Lighstorm::Models::Invoice.new(data)
        end
      end
    end
  end
end
