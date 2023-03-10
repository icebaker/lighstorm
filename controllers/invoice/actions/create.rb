# frozen_string_literal: true

require_relative '../../../ports/grpc'
require_relative '../../../models/errors'
require_relative '../../../helpers/time_expression'
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

        def self.prepare(payable:, expires_in:, description: nil, amount: nil)
          request = {
            service: :lightning,
            method: :add_invoice,
            params: {
              memo: description,
              # Lightning Invoice Expiration: UX Considerations
              # https://d.elor.me/2022/01/lightning-invoice-expiration-ux-considerations/
              expiry: Helpers::TimeExpression.seconds(expires_in)
            }
          }

          request[:params][:value_msat] = amount[:millisatoshis] unless amount.nil?

          if payable.to_sym == :indefinitely
            request[:params][:is_amp] = true
          elsif payable.to_sym != :once
            raise Errors::ArgumentError, "payable: accepts 'indefinitely' or 'once', '#{payable}' is not valid."
          end

          request
        end

        def self.dispatch(grpc_request, &vcr)
          vcr.nil? ? call(grpc_request) : vcr.call(-> { call(grpc_request) }, :dispatch)
        end

        def self.adapt(response)
          Lighstorm::Adapter::Invoice.add_invoice(response)
        end

        def self.fetch(adapted, &vcr)
          FindBySecretHash.data(adapted[:secret][:hash], &vcr)
        end

        def self.model(data)
          FindBySecretHash.model(data)
        end

        def self.perform(payable:, expires_in:, description: nil, amount: nil, preview: false, &vcr)
          grpc_request = prepare(
            description: description,
            amount: amount,
            expires_in: expires_in,
            payable: payable
          )

          return grpc_request if preview

          response = dispatch(grpc_request, &vcr)

          adapted = adapt(response)

          data = fetch(adapted, &vcr)
          model = self.model(data)

          Action::Output.new({ response: response, result: model })
        end
      end
    end
  end
end
