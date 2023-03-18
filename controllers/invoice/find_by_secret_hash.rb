# frozen_string_literal: true

require_relative '../../ports/grpc'
require_relative '../../adapters/invoice'
require_relative '../../models/invoice'

module Lighstorm
  module Controllers
    module Invoice
      module FindBySecretHash
        def self.fetch(components, secret_hash)
          { response: {
            at: Time.now,
            lookup_invoice: components[:grpc].lightning.lookup_invoice(r_hash_str: secret_hash).to_h
          }, exception: nil }
        rescue StandardError => e
          { exception: e }
        end

        def self.adapt(raw)
          raise 'missing at' if raw[:at].nil?

          {
            lookup_invoice: Lighstorm::Adapter::Invoice.lookup_invoice(
              raw[:lookup_invoice],
              raw[:at]
            )
          }
        end

        def self.transform(adapted)
          adapted[:lookup_invoice][:known] = true
          adapted[:lookup_invoice]
        end

        def self.data(components, secret_hash, &vcr)
          raw = if vcr.nil?
                  fetch(components, secret_hash)
                else
                  vcr.call(-> { fetch(components, secret_hash) })
                end

          adapted = adapt(raw[:response])

          transform(adapted)
        end

        def self.model(data)
          Lighstorm::Models::Invoice.new(data)
        end
      end
    end
  end
end
