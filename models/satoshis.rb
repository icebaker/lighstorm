# frozen_string_literal: true

require_relative '../ports/dsl/lighstorm/errors'

module Lighstorm
  module Models
    class Satoshis
      def initialize(milisatoshis: nil)
        raise MissingMilisatoshisError, 'missing milisatoshis' if milisatoshis.nil?

        @amount_in_milisatoshis = milisatoshis
      end

      def parts_per_million(reference_milisatoshis)
        (
          (
            if reference_milisatoshis.zero?
              0
            else
              @amount_in_milisatoshis.to_f / reference_milisatoshis
            end
          ) * 1_000_000.0
        )
      end

      def milisatoshis
        @amount_in_milisatoshis
      end

      def satoshis
        @amount_in_milisatoshis.to_f / 1000.0
      end

      def bitcoins
        @amount_in_milisatoshis.to_f / 100_000_000_000
      end

      def sats
        satoshis
      end

      def msats
        milisatoshis
      end

      def btc
        bitcoins
      end

      def to_h
        {
          milisatoshis: milisatoshis
        }
      end
    end
  end
end
