# frozen_string_literal: true

require_relative '../../ports/grpc'
require_relative '../../adapters/invoice'
require_relative '../../models/invoice'

module Lighstorm
  module Controllers
    module Invoice
      module Decode
        def self.fetch(components, code)
          {
            _code: code,
            decode_pay_req: components[:grpc].lightning.decode_pay_req(pay_req: code).to_h
          }
        end

        def self.adapt(raw)
          {
            decode_pay_req: Lighstorm::Adapter::Invoice.decode_pay_req(
              raw[:decode_pay_req], raw[:_code]
            )
          }
        end

        def self.transform(adapted)
          adapted[:decode_pay_req]
        end

        def self.data(components, code, &vcr)
          raw = vcr.nil? ? fetch(components, code) : vcr.call(-> { fetch(components, code) })

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
