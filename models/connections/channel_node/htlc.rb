# frozen_string_literal: true

require_relative '../../satoshis'
require_relative '../../rate'

require_relative '../../../components/lnd'

module Lighstorm
  module Models
    class HTLC
      attr_reader :minimum, :maximum

      def initialize(policy, channel, _node)
        @channel = channel
        @policy = policy

        return unless policy.data

        @minimum = Satoshis.new(milisatoshis: policy.data.min_htlc)

        @maximum = Satoshis.new(milisatoshis: policy.data.max_htlc_msat)
      end

      def to_h
        {
          minimum: @minimum.to_h,
          maximum: @maximum.to_h
        }
      end
    end
  end
end
