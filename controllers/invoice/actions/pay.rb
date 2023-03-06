# frozen_string_literal: true

require_relative '../../../ports/grpc'
require_relative '../../../models/errors'
require_relative '../../../models/edges/payment'
require_relative '../../../adapters/edges/payment'
require_relative '../../invoice'
require_relative '../../action'
require_relative '../../node/myself'

module Lighstorm
  module Controllers
    module Invoice
      module Pay
        def self.call(grpc_request)
          result = []
          Lighstorm::Ports::GRPC.send(grpc_request[:service]).send(
            grpc_request[:method], grpc_request[:params]
          ) do |response|
            result << response.to_h
          end
          result
        end

        def self.prepare(request_code: nil, millisatoshis: nil)
          {
            service: :router,
            method: :send_payment_v2,
            params: {
              payment_request: request_code,
              # amt_msat: millisatoshis,
              timeout_seconds: 5,
              allow_self_payment: true
            }
          }
        end

        def self.dispatch(grpc_request, &vcr)
          vcr.nil? ? call(grpc_request) : vcr.call(-> { call(grpc_request) }, :dispatch)
        end

        def self.fetch(&vcr)
          Node::Myself.data(&vcr)
        end

        def self.adapt(response, node_get_info)
          Adapter::Payment.send_payment_v2(response, node_get_info)
        end

        def self.model(data)
          Models::Payment.new(data)
        end

        def self.perform(request_code: nil, millisatoshis: nil, preview: false, &vcr)
          grpc_request = prepare(
            request_code: request_code, millisatoshis: millisatoshis
          )

          return grpc_request if preview

          response = dispatch(grpc_request, &vcr)

          data = fetch(&vcr)

          adapted = adapt(response, data)

          model = self.model(adapted)

          Action::Output.new({ response: response, result: model })
        end
      end
    end
  end
end
