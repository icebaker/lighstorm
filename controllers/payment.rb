# frozen_string_literal: true

require_relative './payment/all'

module Lighstorm
  module Controllers
    module Payment
      def self.all(purpose: nil, limit: nil)
        All.model(All.data(purpose: purpose, limit: limit))
      end

      def self.first(purpose: nil)
        All.model(All.data(purpose: purpose)).first
      end

      def self.last(purpose: nil)
        All.model(All.data(purpose: purpose)).last
      end
    end
  end
end
