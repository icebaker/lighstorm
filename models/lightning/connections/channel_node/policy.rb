# frozen_string_literal: true

require_relative 'fee'
require_relative 'htlc'

module Lighstorm
  module Model
    module Lightning
      class Policy
        attr_reader :transaction

        def initialize(data, components, transaction)
          @data = data
          @components = components
          @transaction = transaction
        end

        def fee
          @fee ||= Fee.new(self, @components, @data ? @data[:fee] : {})
        end

        def htlc
          @htlc ||= HTLC.new(@data ? @data[:htlc] : {})
        end

        def to_h
          { fee: fee.to_h, htlc: htlc.to_h }
        end

        def dump
          result = Marshal.load(Marshal.dump(@data))

          result = result.merge({ fee: fee.dump }) if @data && @data[:fee]
          result = result.merge({ htlc: htlc.dump }) if @data && @data[:htlc]

          result
        end
      end
    end
  end
end
