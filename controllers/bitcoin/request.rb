# frozen_string_literal: true

require 'digest'

require_relative '../concerns/impersonatable'
require_relative './request/decode'
require_relative './address/actions/create'
require_relative '../action'

module Lighstorm
  module Controller
    module Bitcoin
      module Request
        extend Impersonatable

        class DSL < Impersonatable::DSL
          def create(address: nil, format: 'taproot', amount: nil, description: nil, message: nil, preview: false, &vcr)
            if address.nil?
              address_action = Address::Create.perform(components, format: format, preview: preview, &vcr)
              return address_action if preview

              address = address_action.result.to_h
            else
              address_action = nil
            end

            model = Model::Bitcoin::Request.new(
              {
                _key: Digest::SHA256.hexdigest(
                  [
                    address ? address[:code] : nil,
                    amount ? amount[:millisatoshis] : nil,
                    description, message
                  ].join('/')
                ),
                address: address, amount: amount, description: description, message: message
              },
              components
            )

            Action::Output.new({
                                 request: address_action&.request,
                                 response: address_action&.response,
                                 result: model
                               })
          end

          def decode(uri)
            Decode.model(Decode.data(uri: uri), components)
          end
        end
      end
    end
  end
end
