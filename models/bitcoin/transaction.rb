# frozen_string_literal: true

require_relative '../satoshis'
require_relative './address'

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

        def to
          @to ||= if @data[:to]
                    Struct.new(:data) do
                      def address
                        @address ||= Address.new({ code: data[:address][:code] }, nil)
                      end

                      def to_h
                        { address: address.to_h }
                      end
                    end.new(@data[:to])
                  end
        end

        def to_h
          output = {
            _key: _key,
            at: at,
            hash: hash,
            amount: amount.to_h,
            fee: fee.to_h,
            description: description
          }

          output[:to] = to.to_h if to

          output
        end
      end
    end
  end
end
