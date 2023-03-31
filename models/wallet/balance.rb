# frozen_string_literal: true

module Lighstorm
  module Models
    module Wallet
      class Balance
        attr_reader :_key, :at

        def initialize(data)
          @data = data

          @_key = @data[:_key]
          @at = @data[:at]
        end

        def lightning
          @lightning ||= Satoshis.new(millisatoshis: @data[:lightning][:millisatoshis])
        end

        def bitcoin
          @bitcoin ||= Satoshis.new(millisatoshis: @data[:bitcoin][:millisatoshis])
        end

        def total
          @total ||= Satoshis.new(millisatoshis: @data[:total][:millisatoshis])
        end

        def to_h
          {
            _key: _key,
            at: at,
            lightning: lightning.to_h,
            bitcoin: bitcoin.to_h,
            total: total.to_h
          }
        end
      end
    end
  end
end
