# frozen_string_literal: true

require_relative '../../../ports/grpc'
require_relative '../../../adapters/lightning/invoice'
require_relative '../../../models/lightning/invoice'

module Lighstorm
  module Controller
    module Lightning
      module Secret
        module ValidProof
          def self.fetch(components, invoice_main_secret_hash)
            { response: {
              at: Time.now,
              lookup_invoice: components[:grpc].lightning.lookup_invoice(r_hash_str: invoice_main_secret_hash).to_h
            }, exception: nil }
          rescue StandardError => e
            { exception: e }
          end

          def self.adapt(raw)
            {
              lookup_invoice: Lighstorm::Adapter::Lightning::Invoice.lookup_invoice(
                raw[:lookup_invoice],
                raw[:at]
              )
            }
          end

          def self.transform(adapted, candidate_proof)
            return true if adapted[:lookup_invoice][:secret][:proof] == candidate_proof

            return false if adapted[:lookup_invoice][:payments].nil? ||
                            adapted[:lookup_invoice][:payments].empty?

            !adapted[:lookup_invoice][:payments].find do |payment|
              next if payment[:secret].nil?

              payment[:secret][:proof] == candidate_proof
            end.nil?
          end

          def self.data(components, invoice_main_secret_hash, candidate_proof, &vcr)
            raise 'Invalid proof' if candidate_proof.size != 64

            raw = if vcr.nil?
                    fetch(components, invoice_main_secret_hash)
                  else
                    vcr.call(-> { fetch(components, invoice_main_secret_hash) })
                  end

            adapted = adapt(raw[:response])

            transform(adapted, candidate_proof)
          end
        end
      end
    end
  end
end
