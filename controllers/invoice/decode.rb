# frozen_string_literal: true

require_relative '../../ports/grpc'
require_relative '../../adapters/invoice_v2'
require_relative '../../models/invoice'

module Lighstorm
  module Controllers
    module Invoice
      module Decode
        def self.fetch(request_code)
          {
            _request_code: request_code,
            decode_pay_req: Ports::GRPC.lightning.decode_pay_req(pay_req: request_code).to_h
          }
        end

        def self.adapt(raw)
          {
            decode_pay_req: Lighstorm::Adapter::InvoiceV2.decode_pay_req(
              raw[:decode_pay_req], raw[:_request_code]
            )
          }
        end

        def self.transform(adapted)
          adapted[:decode_pay_req]
        end

        def self.data(request_code, &vcr)
          raw = vcr.nil? ? fetch(request_code) : vcr.call(-> { fetch(request_code) })

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
