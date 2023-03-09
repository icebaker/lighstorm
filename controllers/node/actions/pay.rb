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

module Lighstorm
  module Controllers
    module Node
      module Pay
        def self.call(grpc_request)
          result = []
          Lighstorm::Ports::GRPC.send(grpc_request[:service]).send(
            grpc_request[:method], grpc_request[:params]
          ) do |response|
            result << response.to_h
          end
          result
        rescue StandardError => e
          { _error: e }
        end

        def self.prepare(public_key:, millisatoshis:, seconds:, secret:, through:, message: nil)
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
              amt_msat: millisatoshis,
              timeout_seconds: seconds,
              allow_self_payment: true,
              dest_custom_records: {}
            }
          }

          if !message.nil? && !message.empty?
            # https://github.com/satoshisstream/satoshis.stream/blob/main/TLV_registry.md
            request[:params][:dest_custom_records][34_349_334] = [message].pack('H*')
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

        def self.dispatch(grpc_request, &vcr)
          vcr.nil? ? call(grpc_request) : vcr.call(-> { call(grpc_request) }, :dispatch)
        end

        def self.fetch(&vcr)
          Node::Myself.data(&vcr)
        end

        def self.adapt(response, node_get_info)
          Adapter::Payment.send_payment_v2(response.last, node_get_info, :node_send)
        end

        def self.model(data)
          Models::Payment.new(data)
        end

        def self.perform(public_key:, millisatoshis:, through:, seconds:, message: nil, secret: nil, preview: false, &vcr)
          secret = Models::Secret.generate.to_h if secret.nil? && through.to_sym == :keysend

          grpc_request = prepare(
            public_key: public_key,
            millisatoshis: millisatoshis,
            through: through,
            seconds: seconds,
            secret: secret,
            message: message
          )

          return grpc_request if preview

          response = dispatch(grpc_request, &vcr)

          data = fetch(&vcr)

          adapted = adapt(response, data)

          model = self.model(adapted)

          Action::Output.new({ response: response, result: model })
        end
      end
    end
  end
end
