# frozen_string_literal: true

require 'digest'
require_relative 'satoshis'

module Lighstorm
  module Models
    class PaymentRequest
      attr_reader :_key, :code, :address

      def initialize(data)
        @data = data

        @_key = data[:_key] || Digest::SHA256.hexdigest(
          data[:code] || "#{data[:amount][:millisatoshis]}#{Time.now}"
        )

        @code = data[:code]

        @address = data[:address]
      end

      def amount
        @amount ||= Satoshis.new(millisatoshis: @data[:amount][:millisatoshis])
      end

      def description
        @description ||= Struct.new(:data) do
          def memo
            data[:memo]
          end

          def hash
            data[:hash]
          end

          def to_h
            { memo: memo, hash: hash }
          end
        end.new(@data[:description] || {})
      end

      def secret
        @secret ||= Struct.new(:data) do
          def preimage
            data[:preimage]
          end

          def hash
            data[:hash]
          end

          def to_h
            # Don't expose 'secret' by default: Security
            { hash: hash }
          end
        end.new(@data[:secret] || {})
      end

      def to_h
        # Don't expose 'address' by default: Privacy
        {
          _key: _key,
          code: code,
          amount: amount.to_h,
          description: description.to_h,
          secret: secret.to_h
        }
      end
    end
  end
end
