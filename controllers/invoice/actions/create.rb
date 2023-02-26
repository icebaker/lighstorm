# frozen_string_literal: true

require_relative '../../../ports/grpc'
require_relative '../../../models/errors'
require_relative '../../invoice'

module Lighstorm
  module Controllers
    module Invoice
      module Create
        OUTPUT = Struct.new(:data) do
          def response
            data[:response]
          end

          def result
            data[:result]
          end

          def to_h
            {
              response: response,
              result: result.to_h
            }
          end
        end

        def self.call(grpc_request)
          LND.instance.middleware("lightning.#{grpc_request[:method]}") do
            LND.instance.client.lightning.send(grpc_request[:method], grpc_request[:params])
          end.to_h
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

          OUTPUT.new({ response: response, result: model })

          # # result = Invoice.find_by_secret_hash(response[:r_hash].unpack1('H*'))

          # # OUTPUT.new({ response: reponse, result: result })
        end
      end
    end
  end
end
