# frozen_string_literal: true

require_relative '../../ports/grpc'
require_relative '../../adapters/invoice'
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
            _request_code: raw[:_request_code],
            decode_pay_req: Lighstorm::Adapter::Invoice.decode_pay_req(raw[:decode_pay_req])
          }
        end

        def self.transform(adapted)
          adapted[:decode_pay_req][:request][:code] = adapted[:_request_code]
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
