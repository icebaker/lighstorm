# frozen_string_literal: true

require_relative './invoice/all'
require_relative './invoice/decode'
require_relative './invoice/find_by_secret_hash'
require_relative './invoice/actions/create'

module Lighstorm
  module Controllers
    module Invoice
      def self.all(limit: nil, spontaneous: false)
        All.model(All.data(limit: limit, spontaneous: spontaneous))
      end

      def self.first
        All.model(All.data).first
      end

      def self.last
        All.model(All.data).last
      end

      def self.find_by_secret_hash(secret_hash)
        FindBySecretHash.model(FindBySecretHash.data(secret_hash))
      end

      def self.decode(request_code, &vcr)
        Decode.model(Decode.data(request_code, &vcr))
      end

      def self.create(
        payable:,
        description: nil, millisatoshis: nil,
        # Lightning Invoice Expiration: UX Considerations
        # https://d.elor.me/2022/01/lightning-invoice-expiration-ux-considerations/
        expires_in: { hours: 24 },
        preview: false, &vcr
      )
        Create.perform(
          payable: payable,
          description: description,
          millisatoshis: millisatoshis,
          expires_in: expires_in,
          preview: preview,
          &vcr
        )
      end
    end
  end
end
