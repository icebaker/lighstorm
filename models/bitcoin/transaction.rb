# frozen_string_literal: true

require_relative '../satoshis'

module Lighstorm
  module Model
    module Bitcoin
      class Transaction
        attr_reader :_key, :at, :hash, :description

        def initialize(data)
          @data = data

          @_key = @data[:_key]
          @at = @data[:at]
          @hash = @data[:hash]
          @description = @data[:description]
        end

        def amount
          @amount ||= Satoshis.new(millisatoshis: @data[:amount][:millisatoshis])
        end

        def fee
          @fee ||= Satoshis.new(millisatoshis: @data[:fee][:millisatoshis])
        end

        def to_h
          {
            _key: _key,
            at: at,
            hash: hash,
            amount: amount.to_h,
            fee: fee.to_h,
            description: description
          }
        end
      end
    end
  end
end
