# frozen_string_literal: true

require 'securerandom'
require 'digest'

require_relative '../../../ports/grpc'
require_relative '../../../models/secret'
require_relative '../../../models/errors'
require_relative '../../../models/edges/payment'
require_relative '../../../adapters/edges/payment'
require_relative '../../invoice'
require_relative '../../action'
require_relative '../../node/myself'

require_relative '../../payment/actions/pay'

module Lighstorm
  module Controllers
    module Node
      module Pay
        def self.dispatch(grpc_request, &vcr)
          Payment::Pay.dispatch(grpc_request, &vcr)
        end

        def self.fetch(&vcr)
          Payment::Pay.fetch(&vcr)
        end

        def self.adapt(data, node_get_info)
          Payment::Pay.adapt(data, node_get_info)
        end

        def self.model(data)
          Payment::Pay.model(data)
        end

        def self.prepare(public_key:, amount:, times_out_in:, secret:, through:, message: nil)
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

          if through.to_sym == :keysend
            request[:params][:payment_hash] = [secret[:hash]].pack('H*')
            request[:params][:dest_custom_records][5_482_373_484] = [secret[:preimage]].pack('H*')
          elsif through.to_sym == :amp
            request[:params][:amp] = true
          end

          request[:params].delete(:dest_custom_records) if request[:params][:dest_custom_records].empty?

          request
        end

        def self.perform(
          public_key:, amount:, through:,
          times_out_in:,
          message: nil, secret: nil,
          preview: false, &vcr
        )
          secret = Models::Secret.create.to_h if secret.nil? && through.to_sym == :keysend

          grpc_request = prepare(
            public_key: public_key,
            amount: amount,
            through: through,
            times_out_in: times_out_in,
            secret: secret,
            message: message
          )

          return grpc_request if preview

          response = dispatch(grpc_request, &vcr)

          Payment::Pay.raise_error_if_exists!(response)

          data = fetch(&vcr)

          adapted = adapt(response, data)

          model = self.model(adapted)

          Payment::Pay.raise_failure_if_exists!(model, response)

          Action::Output.new({ response: response[:response], result: model })
        end
      end
    end
  end
end
