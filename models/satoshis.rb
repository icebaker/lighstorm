# frozen_string_literal: true

require_relative '../ports/dsl/lighstorm/errors'

module Lighstorm
  module Models
    class Satoshis
      def initialize(millisatoshis: nil, bitcoins: nil)
        if [millisatoshis, bitcoins].compact.empty?
          raise MissingMillisatoshisError, 'missing millisatoshis'
        elsif [millisatoshis, bitcoins].compact.size > 1
          raise Errors::TooManyArgumentsError, 'you need to pass millisatoshis: or bitcoins:, not both'
        end

        if !millisatoshis.nil?
          @amount_in_millisatoshis = millisatoshis
        elsif !bitcoins.nil?
          @amount_in_millisatoshis = (bitcoins.to_f * 100_000_000_000.0).to_i
        end
      end

      def parts_per_million(reference_millisatoshis)
        (
          (
            if reference_millisatoshis.zero?
              0
            else
              @amount_in_millisatoshis.to_f / reference_millisatoshis
            end
          ) * 1_000_000.0
        )
      end

      def millisatoshis
        @amount_in_millisatoshis
      end

      def satoshis
        @amount_in_millisatoshis.to_f / 1000.0
      end

      def bitcoins
        @amount_in_millisatoshis.to_f / 100_000_000_000
      end

      def sats
        satoshis
      end

      def msats
        millisatoshis
      end

      def btc
        bitcoins
      end

      def to_h
        {
          millisatoshis: millisatoshis
        }
      end
    end
  end
end
