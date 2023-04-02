# frozen_string_literal: true

require_relative '../../../../ports/grpc'
require_relative '../../../../models/errors'
require_relative '../../../../adapters/bitcoin/transaction'
require_relative '../../../../controllers/bitcoin/transaction/all'
require_relative '../../../action'

module Lighstorm
  module Controller
    module Bitcoin
      module Address
        module Pay
          def self.call(components, grpc_request)
            response = components[:grpc].send(grpc_request[:service]).send(
              grpc_request[:method], grpc_request[:params]
            ).to_h

            { response: response, exception: nil }
          rescue StandardError => e
            { exception: e }
          end

          def self.prepare(address_code:, amount:, fee:, description:, required_confirmations:)
            # required_confirmations:
            #    1: Fast and low-value transactions, such as buying a cup of coffee
            #    2: Low-value transactions that require faster processing, such as online purchases
            #    3: Moderate-value transactions, such as purchasing a computer or paying a bill
            #    6: High-value transactions, such as buying a car or real estate
            #  12+: Extremely high-value transactions, such as purchasing a private island or artwork

            # GRPC::Unknown: 2:transaction output is dust.
            # dust_limit = 3 * 25 * 31 = 2325 satoshis
            # This formula doesn't seem to be working...
            request = {
              service: :lightning,
              method: :send_coins,
              params: {
                addr: address_code,
                amount: (amount[:millisatoshis].to_f / 1000.0).to_i,
                sat_per_vbyte: fee[:satoshis_per_vitual_byte],
                min_confs: required_confirmations
              }
            }

            request[:params][:label] = description if !description.nil? && !description.empty?

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
            Adapter::Bitcoin::Transaction.send_coins(response[:response])
          end

          def self.fetch(components, adapted, &vcr)
            Controller::Bitcoin::Transaction::All.data(
              components, hash: adapted[:hash], limit: 1, &vcr
            )
          end

          def self.model(data)
            Controller::Bitcoin::Transaction::All.model(data)
          end

          def self.perform(
            components,
            address_code:, amount:, fee:, description: nil, required_confirmations: 6,
            preview: false, &vcr
          )
            grpc_request = prepare(
              address_code: address_code,
              amount: amount,
              fee: fee,
              description: description,
              required_confirmations: required_confirmations
            )

            return grpc_request if preview

            response = dispatch(components, grpc_request, &vcr)

            raise_error_if_exists!(grpc_request, response)

            adapted = adapt(response)

            data = fetch(components, adapted, &vcr)
            model = self.model(data).first

            Action::Output.new({ request: grpc_request, response: response[:response], result: model })
          end

          def self.raise_error_if_exists!(request, response)
            return if response[:exception].nil?

            if response[:exception].message =~ /transaction output is dust/
              raise AmountBelowDustLimitError.new(
                "Amount is too low and considered dust (#{request[:params][:amount]} satoshis).",
                request: request, grpc: response[:exception]
              )
            end

            raise RequestError.new(
              response[:exception].message,
              request: request, grpc: response[:exception]
            )
          end
        end
      end
    end
  end
end
