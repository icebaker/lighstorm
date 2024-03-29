# frozen_string_literal: true

require_relative '../../../ports/grpc'
require_relative '../../../adapters/lightning/invoice'
require_relative '../../../models/lightning/invoice'

module Lighstorm
  module Controller
    module Lightning
      module Invoice
        module FindByCode
          def self.fetch(components, code)
            at = Time.now

            decoded = components[:grpc].lightning.decode_pay_req(pay_req: code).to_h

            { response: {
              at: at,
              decode_pay_req: decoded,
              lookup_invoice: components[:grpc].lightning.lookup_invoice(r_hash_str: decoded[:payment_hash]).to_h
            }, exception: nil }
          rescue StandardError => e
            { exception: e }
          end

          def self.adapt(raw)
            raise 'missing at' if raw[:at].nil?

            {
              lookup_invoice: Lighstorm::Adapter::Lightning::Invoice.lookup_invoice(
                raw[:lookup_invoice],
                raw[:at]
              )
            }
          end

          def self.transform(adapted)
            adapted[:lookup_invoice][:known] = true
            adapted[:lookup_invoice]
          end

          def self.data(components, code, &vcr)
            raw = if vcr.nil?
                    fetch(components, code.sub('lightning:', ''))
                  else
                    vcr.call(-> { fetch(components, code.sub('lightning:', '')) })
                  end

            raise_error_if_exists!(raw)

            adapted = adapt(raw[:response])

            transform(adapted)
          end

          def self.model(data, components)
            Lighstorm::Model::Lightning::Invoice.new(data, components)
          end

          def self.raise_error_if_exists!(response)
            return if response[:exception].nil?

            if response[:exception].is_a?(GRPC::NotFound)
              raise NoInvoiceFoundError.new(
                "Invoice not found. Try using Invoice.decode if you don't own the invoice.",
                grpc: response[:exception]
              )
            end

            raise LighstormError.new(grpc: response[:exception])
          end
        end
      end
    end
  end
end
