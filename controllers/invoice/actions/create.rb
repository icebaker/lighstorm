# frozen_string_literal: true

require_relative '../../../ports/grpc'
require_relative '../../../models/errors'
require_relative '../../invoice'

module Lighstorm
  module Controllers
    module Invoice
      module Create
        def self.perform(description: nil, milisatoshis: nil, preview: false, fake: nil)
          grpc_request = {
            service: :lightning,
            method: :add_invoice,
            params: {
              memo: description,
              value_msat: milisatoshis
            }
          }

          return grpc_request if preview

          # expiry: Default is 86400 (24 hours).
          response = if fake.nil?
                       LND.instance.middleware("lightning.#{grpc_request[:method]}") do
                         LND.instance.client.lightning.send(grpc_request[:method], grpc_request[:params])
                       end.to_h
                     else
                       fake
                     end

          Invoice.find_by_secret_hash(response[:r_hash].unpack1('H*'))

          # TODO
          # find_by_secret_hash(response[:r_hash].unpack1('H*'))
          # response
        end
      end
    end
  end
end
