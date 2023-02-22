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
    end
  end
end
