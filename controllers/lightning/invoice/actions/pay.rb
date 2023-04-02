# frozen_string_literal: true

require_relative '../../../../ports/grpc'
require_relative '../../../../models/errors'
require_relative '../../../../models/lightning/edges/payment'
require_relative '../../../../adapters/lightning/edges/payment'
require_relative '../../invoice'
require_relative '../../../action'
require_relative '../../node/myself'

require_relative '../../payment/actions/pay'

module Lighstorm
  module Controller
    module Lightning
      module Invoice
        module Pay
          def self.dispatch(components, grpc_request, &vcr)
            Payment::Pay.dispatch(components, grpc_request, &vcr)
          end

          def self.fetch(components, code, &vcr)
            Payment::Pay.fetch(components, code, &vcr)
          end

          def self.adapt(data, node_get_info)
            Payment::Pay.adapt(data, node_get_info)
          end

          def self.model(data, components)
            Payment::Pay.model(data, components)
          end

          def self.prepare(code:, times_out_in:, amount: nil, fee: nil, message: nil)
            request = {
              service: :router,
              method: :send_payment_v2,
              params: {
                payment_request: code,
                timeout_seconds: Helpers::TimeExpression.seconds(times_out_in),
                allow_self_payment: true,
                dest_custom_records: {}
              }
            }

            request[:params][:amt_msat] = amount[:millisatoshis] unless amount.nil?

            unless fee.nil? || fee[:maximum].nil? || fee[:maximum][:millisatoshis].nil?
              request[:params][:fee_limit_msat] = fee[:maximum][:millisatoshis]
            end

            if !message.nil? && !message.empty?
              # https://github.com/satoshisstream/satoshis.stream/blob/main/TLV_registry.md
              request[:params][:dest_custom_records][34_349_334] = message
            end

            request[:params].delete(:dest_custom_records) if request[:params][:dest_custom_records].empty?

            request
          end

          def self.perform(
            components,
            times_out_in:, code:,
            amount: nil, fee: nil,
            message: nil,
            preview: false, &vcr
          )
            grpc_request = prepare(
              code: code,
              amount: amount,
              fee: fee,
              message: message,
              times_out_in: times_out_in
            )

            return grpc_request if preview

            response = dispatch(components, grpc_request, &vcr)

            Payment::Pay.raise_error_if_exists!(grpc_request, response)

            data = fetch(components, code, &vcr)

            adapted = adapt(response, data)

            model = self.model(adapted, components)

            Payment::Pay.raise_failure_if_exists!(model, grpc_request, response)

            Action::Output.new({ request: grpc_request, response: response[:response], result: model })
          end
        end
      end
    end
  end
end
