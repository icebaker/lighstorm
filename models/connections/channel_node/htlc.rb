# frozen_string_literal: true

require_relative '../../satoshis'
require_relative '../../rate'

require_relative '../../../components/lnd'

module Lighstorm
  module Models
    class HTLC
      def initialize(data)
        @data = data
      end

      def minimum
        @minimum ||= Satoshis.new(milisatoshis: @data[:minimum][:milisatoshis])
      end

      def maximum
        @maximum ||= Satoshis.new(milisatoshis: @data[:maximum][:milisatoshis])
      end

      def blocks
        @blocks ||= Struct.new(:data) do
          def delta
            Struct.new(:data) do
              def minimum
                data[:minimum]
              end

              def to_h
                { minimum: minimum }
              end
            end.new(data[:delta])
          end

          def to_h
            { delta: delta.to_h }
          end
        end.new(@data[:blocks])
      end

      def to_h
        {
          minimum: minimum.to_h,
          maximum: maximum.to_h,
          blocks: blocks.to_h
        }
      end
    end
  end
end
