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

        def specification
          @specification ||= infer_specification(code)
        end

        def to_h
          if created_at || _key
            {
              _key: _key,
              created_at: created_at,
              code: code,
              specification: specification.to_h
            }
          else
            { code: code, specification: specification.to_h }
          end
        end

        private

        def infer_specification(address_code)
          data = case address_code
                 when /^(bc1p|tb1p|bcrt1p)/
                   { format: 'taproot', bip: 341, code: 'P2TR' }
                 when /^(bc1q|tb1q|bcrt1q)/
                   { format: 'segwit', bip: 173, code: 'P2WPKH' }
                 when /^[23]/
                   { format: 'script', bip: 16, code: 'P2SH' }
                 when /^[mn1]/
                   { format: 'legacy', bip: nil, code: 'P2PKH' }
                 else
                   { format: 'unknown', bip: nil, code: nil }
                 end

          Struct.new(:data) do
            def format
              data[:format]
            end

            def code
              data[:code]
            end

            def bip
              data[:bip]
            end

            def to_h
              { format: format, code: code, bip: bip }
            end
          end.new(data)
        end
      end
    end
  end
end
