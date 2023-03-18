# frozen_string_literal: true

require_relative './invoice/all'
require_relative './invoice/decode'
require_relative './invoice/find_by_secret_hash'
require_relative './invoice/find_by_code'
require_relative './invoice/actions/create'

module Lighstorm
  module Controllers
    module Invoice
      def self.components
        { grpc: Ports::GRPC }
      end

      def self.all(limit: nil, spontaneous: false)
        All.model(All.data(components, limit: limit, spontaneous: spontaneous))
      end

      def self.first
        All.model(All.data(components)).first
      end

      def self.last
        All.model(All.data(components)).last
      end

      def self.find_by_secret_hash(secret_hash, &vcr)
        FindBySecretHash.model(FindBySecretHash.data(components, secret_hash, &vcr))
      end

      def self.find_by_code(code, &vcr)
        FindByCode.model(FindByCode.data(components, code, &vcr))
      end

      def self.decode(code, &vcr)
        Decode.model(Decode.data(components, code, &vcr))
      end

      def self.create(
        payable:,
        description: nil, amount: nil,
        # Lightning Invoice Expiration: UX Considerations
        # https://d.elor.me/2022/01/lightning-invoice-expiration-ux-considerations/
        expires_in: { hours: 24 },
        preview: false, &vcr
      )
        Create.perform(
          components,
          payable: payable,
          description: description,
          amount: amount,
          expires_in: expires_in,
          preview: preview,
          &vcr
        )
      end
    end
  end
end
