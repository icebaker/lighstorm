# frozen_string_literal: true

require_relative '../../../../ports/grpc'
require_relative '../../../../models/errors'
require_relative '../../../../helpers/time_expression'
require_relative '../../invoice'
require_relative '../../../action'

module Lighstorm
  module Controller
    module Lightning
      module Invoice
        module Create
          def self.call(components, grpc_request)
            components[:grpc].send(grpc_request[:service]).send(
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

          def self.dispatch(components, grpc_request, &vcr)
            if vcr.nil?
              call(components, grpc_request)
            else
              vcr.call(-> { call(components, grpc_request) }, :dispatch)
            end
          end

          def self.adapt(response)
            Lighstorm::Adapter::Lightning::Invoice.add_invoice(response)
          end

          def self.fetch(components, adapted, &vcr)
            FindBySecretHash.data(components, adapted[:secret][:hash], &vcr)
          end

          def self.model(data, components)
            FindBySecretHash.model(data, components)
          end

          def self.perform(
            components,
            payable:, expires_in:, description: nil, amount: nil,
            preview: false, &vcr
          )
            grpc_request = prepare(
              description: description,
              amount: amount,
              expires_in: expires_in,
              payable: payable
            )

            return grpc_request if preview

            response = dispatch(components, grpc_request, &vcr)

            adapted = adapt(response)

            data = fetch(components, adapted, &vcr)
            model = self.model(data, components)

            Action::Output.new({ request: grpc_request, response: response, result: model })
          end
        end
      end
    end
  end
end
