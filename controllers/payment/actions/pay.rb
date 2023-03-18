# frozen_string_literal: true

require 'securerandom'
require 'digest'

require_relative '../../../ports/grpc'
require_relative '../../../models/errors'
require_relative '../../../models/edges/payment'
require_relative '../../../adapters/edges/payment'
require_relative '../../node/myself'
require_relative '../../invoice/decode'

module Lighstorm
  module Controllers
    module Payment
      module Pay
        def self.call(components, grpc_request)
          result = []
          components[:grpc].send(grpc_request[:service]).send(
            grpc_request[:method], grpc_request[:params]
          ) do |response|
            result << response.to_h
          end
          { response: result, exception: nil }
        rescue StandardError => e
          { exception: e }
        end

        def self.dispatch(components, grpc_request, &vcr)
          if vcr.nil?
            call(components, grpc_request)
          else
            vcr.call(-> { call(components, grpc_request) }, :dispatch)
          end
        end

        def self.fetch_all(components, code)
          {
            invoice_decode: code.nil? ? nil : Invoice::Decode.data(components, code),
            node_myself: Node::Myself.data(components)
          }
        end

        def self.fetch(components, code = nil, &vcr)
          raw = vcr.nil? ? fetch_all(components, code) : vcr.call(-> { fetch_all(components, code) })
        end

        def self.adapt(grpc_data, fetch_data)
          Adapter::Payment.send_payment_v2(
            grpc_data[:response].last,
            fetch_data[:node_myself],
            fetch_data[:invoice_decode]
          )
        end

        def self.model(data)
          Models::Payment.new(data)
        end

        def self.raise_error_if_exists!(response)
          return if response[:exception].nil?

          if response[:exception].is_a?(GRPC::AlreadyExists)
            raise AlreadyPaidError.new(
              'The invoice is already paid.',
              grpc: response[:exception]
            )
          end

          if response[:exception].message =~ /amount must not be specified when paying a non-zero/
            raise AmountForNonZeroError.new(
              'Millisatoshis must not be specified when paying a non-zero amount invoice.',
              grpc: response[:exception]
            )
          end

          if response[:exception].message =~ /amount must be specified when paying a zero amount/
            raise MissingMillisatoshisError.new(
              'Millisatoshis must be specified when paying a zero amount invoice.',
              grpc: response[:exception]
            )
          end

          raise PaymentError.new(
            response[:exception].message,
            grpc: response[:exception]
          )
        end

        def self.raise_failure_if_exists!(model, response)
          return unless model.state == 'failed'

          if response[:response].last[:failure_reason] == :FAILURE_REASON_NO_ROUTE
            raise NoRouteFoundError.new(
              response[:response].last[:failure_reason],
              response: response[:response], result: model
            )
          else
            raise PaymentError.new(
              response[:response].last[:failure_reason],
              response: response[:response], result: model
            )
          end
        end
      end
    end
  end
end
