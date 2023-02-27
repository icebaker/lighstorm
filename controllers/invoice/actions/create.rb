# frozen_string_literal: true

require_relative '../../../ports/grpc'
require_relative '../../../models/errors'
require_relative '../../invoice'
require_relative '../../action'

module Lighstorm
  module Controllers
    module Invoice
      module Create
        def self.call(grpc_request)
          Lighstorm::Ports::GRPC.send(grpc_request[:service]).send(
            grpc_request[:method], grpc_request[:params]
          ).to_h
        end

        def self.prepare(description: nil, milisatoshis: nil)
          {
            service: :lightning,
            method: :add_invoice,
            params: {
              memo: description,
              value_msat: milisatoshis
            }
          }
        end

        def self.dispatch(grpc_request, &vcr)
          vcr.nil? ? call(grpc_request) : vcr.call(-> { call(grpc_request) }, :dispatch)
        end

        def self.adapt(response)
          Lighstorm::Adapter::Invoice.add_invoice(response)
        end

        def self.fetch(adapted, &vcr)
          FindBySecretHash.data(adapted[:request][:secret][:hash], &vcr)
        end

        def self.model(data)
          FindBySecretHash.model(data)
        end

        def self.perform(description: nil, milisatoshis: nil, preview: false, &vcr)
          grpc_request = prepare(
            description: description, milisatoshis: milisatoshis
          )

          return grpc_request if preview

          response = dispatch(grpc_request, &vcr)

          adapted = adapt(response)

          data = fetch(adapted)
          model = self.model(data)

          Action::Output.new({ response: response, result: model })
        end
      end
    end
  end
end
