# frozen_string_literal: true

require_relative '../../../../ports/grpc'
require_relative '../../../../adapters/bitcoin/address'
require_relative '../../../../models/bitcoin/address'
require_relative '../../../action'

module Lighstorm
  module Controller
    module Bitcoin
      module Address
        module Create
          def self.call(components, grpc_request)
            {
              at: Time.now,
              new_address: components[:grpc].send(grpc_request[:service]).send(
                grpc_request[:method], grpc_request[:params]
              ).to_h
            }
          end

          def self.prepare
            # WITNESS_PUBKEY_HASH (0)
            # A modern and efficient Bitcoin address type. It uses less space in transactions,
            # so it has lower fees. Addresses usually start with "bc1" (mainnet) or "tb1" (testnet).

            # NESTED_PUBKEY_HASH (1)
            # \A backward-compatible version of the modern address. It works with older wallets and
            # services but has slightly higher fees. Addresses usually start with "3" (mainnet)
            # or "2" (testnet).

            # UNUSED_WITNESS_PUBKEY_HASH (2)
            # An unused version of the modern address. It's like having a reserved spot for a future
            # address, but it's not being used right now.

            # UNUSED_NESTED_PUBKEY_HASH (3)
            # An unused version of the backward-compatible address. Similar to the unused modern
            # address, it's a reserved spot for a future address but not in use currently.

            # TAPROOT_PUBKEY (4): A new type of Bitcoin address that comes with the Taproot upgrade.
            # It improves privacy and supports more complex transactions (like smart contracts).
            # Addresses usually start with "bc1p" (mainnet) or "tb1p" (testnet).

            # UNUSED_TAPROOT_PUBKEY (5)
            # An unused version of the Taproot address. Like the other unused addresses, it's a
            # reserved spot for a future address but not in use at the moment.
            {
              service: :lightning,
              method: :new_address,
              params: {
                type: :WITNESS_PUBKEY_HASH
              }
            }
          end

          def self.dispatch(components, grpc_request, &vcr)
            if vcr.nil?
              call(components, grpc_request)
            else
              vcr.call(-> { call(components, grpc_request) }, :dispatch)
            end
          end

          def self.adapt(response)
            Lighstorm::Adapter::Bitcoin::Address.new_address(response[:new_address]).merge(
              created_at: response[:at]
            )
          end

          def self.model(data, components)
            Model::Bitcoin::Address.new(data, components)
          end

          def self.perform(components, preview: false, &vcr)
            grpc_request = prepare

            return grpc_request if preview

            response = dispatch(components, grpc_request, &vcr)

            adapted = adapt(response)

            model = self.model(adapted, components)

            Action::Output.new({ request: grpc_request, response: response[:new_address], result: model })
          end
        end
      end
    end
  end
end
