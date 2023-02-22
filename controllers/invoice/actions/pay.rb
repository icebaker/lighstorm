# frozen_string_literal: true

require_relative '../../../ports/grpc'
require_relative '../../../models/errors'

module Lighstorm
  module Controllers
    module Invoice
      module Pay
        def self.perform(_invoice, preview: false, fake: false)
          raise Errors::ToDoError, self

          LND.instance.middleware('router.send_payment_v2') do
            result = []
            LND.instance.client.router.send_payment_v2(
              payment_request: request,
              timeout_seconds: 5,
              allow_self_payment: true
            ) do |response|
              result << response
            end
            result
          end
        end
      end
    end
  end
end
