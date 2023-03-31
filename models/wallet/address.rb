# frozen_string_literal: true

module Lighstorm
  module Models
    module Wallet
      class Address
        attr_reader :_key, :at, :address

        def initialize(data)
          @data = data

          @_key = @data[:_key]
          @at = @data[:at]
          @address = @data[:address]
        end

        def to_h
          {
            _key: _key,
            at: at,
            address: address
          }
        end
      end
    end
  end
end
