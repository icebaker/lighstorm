# frozen_string_literal: true

require_relative '../../../ports/grpc'
require_relative '../../../models/errors'

module Lighstorm
  module Controllers
    module Invoice
      module Create
        def self.perform(description: nil, milisatoshis: nil, preview: false, fake: false)
          raise Errors::ToDoError, self

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
          response = LND.instance.middleware("lightning.#{grpc_request[:method]}") do
            LND.instance.client.lightning.send(grpc_request[:method], grpc_request[:params])
          end

          # TODO
          # find_by_secret_hash(invoice.r_hash.unpack1('H*'))
          # response
        end
      end
    end
  end
end
