# frozen_string_literal: true

require_relative '../../controllers/bitcoin/address/actions/pay'

module Lighstorm
  module Model
    module Bitcoin
      class Address
        attr_reader :_key, :created_at, :code

        def initialize(data, components)
          @data = data
          @components = components

          @_key = @data[:_key]
          @created_at = @data[:created_at]
          @code = @data[:code]
        end

        def pay(
          amount:, fee:,
          description: nil, required_confirmations: 6,
          preview: false, &vcr
        )
          Controller::Bitcoin::Address::Pay.perform(
            @components,
            address_code: code,
            amount: amount, fee: fee, description: description,
            required_confirmations: required_confirmations,
            preview: preview,
            &vcr
          )
        end

        def to_h
          if created_at || _key
            {
              _key: _key,
              created_at: created_at,
              code: code
            }
          else
            { code: code }
          end
        end
      end
    end
  end
end
