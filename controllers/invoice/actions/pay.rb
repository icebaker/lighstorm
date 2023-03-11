# frozen_string_literal: true

require_relative '../../../ports/grpc'
require_relative '../../../models/errors'
require_relative '../../../models/edges/payment'
require_relative '../../../adapters/edges/payment'
require_relative '../../invoice'
require_relative '../../action'
require_relative '../../node/myself'

require_relative '../../payment/actions/pay'

module Lighstorm
  module Controllers
    module Invoice
      module Pay
        def self.dispatch(grpc_request, &vcr)
          Payment::Pay.dispatch(grpc_request, &vcr)
        end

        def self.fetch(request_code, &vcr)
          Payment::Pay.fetch(request_code, &vcr)
        end

        def self.adapt(data, node_get_info)
          Payment::Pay.adapt(data, node_get_info)
        end

        def self.model(data)
          Payment::Pay.model(data)
        end

        def self.prepare(request_code:, times_out_in:, millisatoshis: nil, message: nil)
          request = {
            service: :router,
            method: :send_payment_v2,
            params: {
              payment_request: request_code,
              timeout_seconds: Helpers::TimeExpression.seconds(times_out_in),
              allow_self_payment: true,
              dest_custom_records: {}
            }
          }

          request[:params][:amt_msat] = millisatoshis unless millisatoshis.nil?

          if !message.nil? && !message.empty?
            # https://github.com/satoshisstream/satoshis.stream/blob/main/TLV_registry.md
            request[:params][:dest_custom_records][34_349_334] = message
          end

          request[:params].delete(:dest_custom_records) if request[:params][:dest_custom_records].empty?

          request
        end

        def self.perform(
          times_out_in:, request_code:, millisatoshis: nil, message: nil, preview: false, &vcr
        )
          grpc_request = prepare(
            request_code: request_code,
            millisatoshis: millisatoshis,
            message: message,
            times_out_in: times_out_in
          )

          return grpc_request if preview

          response = dispatch(grpc_request, &vcr)

          Payment::Pay.raise_error_if_exists!(response)

          data = fetch(request_code, &vcr)

          adapted = adapt(response, data)

          model = self.model(adapted)

          Payment::Pay.raise_failure_if_exists!(model, response)

          Action::Output.new({ response: response[:response], result: model })
        end
      end
    end
  end
end
