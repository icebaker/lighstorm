# frozen_string_literal: true

require_relative './transaction/all'

module Lighstorm
  module Controllers
    module Transaction
      def self.all(limit: nil)
        All.model(All.data(limit: limit))
      end
    end
  end
end
