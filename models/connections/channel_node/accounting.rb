# frozen_string_literal: true

require_relative '../../satoshis'

module Lighstorm
  module Models
    class ChannelNodeAccounting
      def initialize(data)
        @data = data
      end

      def balance
        @balance ||= Satoshis.new(milisatoshis: @data[:balance][:milisatoshis])
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
