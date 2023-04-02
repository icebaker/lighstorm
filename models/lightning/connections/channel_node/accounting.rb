# frozen_string_literal: true

require_relative '../../../satoshis'

module Lighstorm
  module Model
    module Lightning
      class ChannelNodeAccounting
        def initialize(data)
          @data = data
        end

        def balance
          @balance ||= Satoshis.new(millisatoshis: @data[:balance][:millisatoshis])
        end

        def to_h
          { balance: balance.to_h }
        end

        def dump
          Marshal.load(Marshal.dump(@data))
        end
      end
    end
  end
end
