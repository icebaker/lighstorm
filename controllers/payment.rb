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
    end
  end
end
