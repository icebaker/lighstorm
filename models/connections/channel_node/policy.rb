# frozen_string_literal: true

require_relative 'fee'
require_relative 'htlc'

module Lighstorm
  module Models
    class Policy
      attr_reader :transaction

      def initialize(data, transaction)
        @data = data
        @transaction = transaction
      end

      def fee
        @fee ||= @data ? Fee.new(self, @data[:fee]) : nil
      end

      def htlc
        @htlc ||= @data ? HTLC.new(@data[:htlc]) : nil
      end

      def to_h
        { fee: fee.to_h, htlc: htlc.to_h }
      end
    end
  end
end
