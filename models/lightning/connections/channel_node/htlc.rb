# frozen_string_literal: true

require_relative '../../../satoshis'
require_relative '../../rate'
require_relative '../../../concerns/protectable'
require_relative 'htlc/blocks/delta'

module Lighstorm
  module Model
    module Lightning
      class HTLC
        include Protectable

        def initialize(data)
          @data = data
        end

        def minimum
          @minimum ||= if @data[:minimum]
                         Satoshis.new(
                           millisatoshis: @data[:minimum][:millisatoshis]
                         )
                       end
        end

        def maximum
          @maximum ||= if @data[:maximum]
                         Satoshis.new(
                           millisatoshis: @data[:maximum][:millisatoshis]
                         )
                       end
        end

        def blocks
          @blocks ||= Struct.new(:data) do
            def delta
              @delta ||= BlocksDelta.new(data[:delta] || {})
            end

            def dump
              { delta: delta.dump }
            end

            def to_h
              { delta: delta.to_h }
            end
          end.new(@data[:blocks] || {})
        end

        def to_h
          {
            minimum: minimum.to_h,
            maximum: maximum.to_h,
            blocks: blocks.to_h
          }
        end

        def dump
          result = Marshal.load(Marshal.dump(@data))

          result = result.merge({ blocks: blocks.dump }) if @data[:blocks]

          result
        end

        def minimum=(value)
          protect!(value)

          @minimum = value[:value]

          @data[:minimum] = { millisatoshis: @minimum.millisatoshis }

          minimum
        end

        def maximum=(value)
          protect!(value)

          @maximum = value[:value]

          @data[:maximum] = { millisatoshis: @maximum.millisatoshis }

          maximum
        end
      end
    end
  end
end
