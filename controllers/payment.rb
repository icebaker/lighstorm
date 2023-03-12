# frozen_string_literal: true

require_relative './payment/all'

module Lighstorm
  module Controllers
    module Payment
      def self.all(purpose: nil, limit: nil, fetch: {})
        All.model(All.data(purpose: purpose, limit: limit, fetch: fetch))
      end

      def self.first(purpose: nil, fetch: {})
        All.model(All.data(purpose: purpose, fetch: fetch)).first
      end

      def self.last(purpose: nil, fetch: {})
        All.model(All.data(purpose: purpose, fetch: fetch)).last
      end

      def self.find_by_secret_hash(secret_hash, &vcr)
        All.model(All.data(secret_hash: secret_hash, &vcr)).first
      end

      def self.find_by_invoice_code(invoice_code, &vcr)
        All.model(All.data(invoice_code: invoice_code, &vcr)).first
      end
    end
  end
end
