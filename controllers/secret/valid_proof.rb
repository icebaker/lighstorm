# frozen_string_literal: true

require_relative '../../ports/grpc'
require_relative '../../adapters/invoice'
require_relative '../../models/invoice'

module Lighstorm
  module Controllers
    module Secret
      module ValidProof
        def self.fetch(invoice_main_secret_hash)
          require 'pry'
          binding.pry
          { response: {
            at: Time.now,
            lookup_invoice: Ports::GRPC.lightning.lookup_invoice(r_hash_str: invoice_main_secret_hash).to_h
          }, exception: nil }
        rescue StandardError => e
          { exception: e }
        end

        def self.adapt(raw)
          {
            lookup_invoice: Lighstorm::Adapter::Invoice.lookup_invoice(
              raw[:lookup_invoice],
              raw[:at]
            )
          }
        end

        def self.transform(adapted, proof)
          return true if adapted[:lookup_invoice][:secret][:preimage] == proof

          return false if adapted[:lookup_invoice][:payments].nil? ||
                          adapted[:lookup_invoice][:payments].empty?

          !adapted[:lookup_invoice][:payments].find do |payment|
            next if payment[:secret].nil?

            payment[:secret][:preimage] == proof
          end.nil?
        end

        def self.data(invoice_main_secret_hash, proof, &vcr)
          raise 'Invalid proof' if proof.size != 64

          raw = if vcr.nil?
                  fetch(invoice_main_secret_hash)
                else
                  vcr.call(-> { fetch(invoice_main_secret_hash) })
                end

          adapted = adapt(raw[:response])

          transform(adapted, proof)
        end
      end
    end
  end
end
