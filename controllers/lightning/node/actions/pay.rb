# frozen_string_literal: true

require 'securerandom'
require 'digest'

require_relative '../../../../ports/grpc'
require_relative '../../../../models/lightning/secret'
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
      module Node
        module Pay
          def self.dispatch(components, grpc_request, &vcr)
            Payment::Pay.dispatch(components, grpc_request, &vcr)
          end

          def self.fetch(components, &vcr)
            Payment::Pay.fetch(components, &vcr)
          end

          def self.adapt(data, node_get_info)
            Payment::Pay.adapt(data, node_get_info)
          end

          def self.model(data, components)
            Payment::Pay.model(data, components)
          end

          def self.prepare(public_key:, amount:, times_out_in:, secret:, through:, fee: nil, message: nil)
            # Appreciation note for people that suffered in the past and shared
            # their knowledge, so we don't have to struggle the same:
            # - https://github.com/lightningnetwork/lnd/discussions/6357
            # - https://docs.lightning.engineering/lightning-network-tools/lnd/send-messages-with-keysend
            # - https://peakd.com/@brianoflondon/lightning-keysend-is-strange-and-how-to-send-keysend-payment-in-lightning-with-the-lnd-rest-api-via-python
            # We are standing on the shoulders of giants, thank you very much. :)
            request = {
              service: :router,
              method: :send_payment_v2,
              params: {
                dest: [public_key].pack('H*'),
                amt_msat: amount[:millisatoshis],
                timeout_seconds: Helpers::TimeExpression.seconds(times_out_in),
                allow_self_payment: true,
                dest_custom_records: {}
              }
            }

            if !message.nil? && !message.empty?
              # https://github.com/satoshisstream/satoshis.stream/blob/main/TLV_registry.md
              request[:params][:dest_custom_records][34_349_334] = message
            end

            unless fee.nil? || fee[:maximum].nil? || fee[:maximum][:millisatoshis].nil?
              request[:params][:fee_limit_msat] = fee[:maximum][:millisatoshis]
            end

            if through.to_sym == :keysend
              request[:params][:payment_hash] = [secret[:hash]].pack('H*')
              request[:params][:dest_custom_records][5_482_373_484] = [secret[:proof]].pack('H*')
            elsif through.to_sym == :amp
              request[:params][:amp] = true
            end

            request[:params].delete(:dest_custom_records) if request[:params][:dest_custom_records].empty?

            request
          end

          def self.perform(
            components,
            public_key:, amount:, through:,
            times_out_in:, fee: nil,
            message: nil, secret: nil,
            preview: false, &vcr
          )
            secret = Model::Lightning::Secret.create.to_h if secret.nil? && through.to_sym == :keysend

            grpc_request = prepare(
              public_key: public_key,
              amount: amount,
              fee: fee,
              through: through,
              times_out_in: times_out_in,
              secret: secret,
              message: message
            )

            return grpc_request if preview

            response = dispatch(components, grpc_request, &vcr)

            Payment::Pay.raise_error_if_exists!(grpc_request, response)

            data = fetch(components, &vcr)

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
