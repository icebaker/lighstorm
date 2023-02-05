# frozen_string_literal: true

require_relative '../../satoshis'
require_relative '../../rate'

module Lighstorm
  module Models
    class Fee
      def initialize(policy, channel, node)
        if node.myself?
          @base = Satoshis.new(
            milisatoshis: channel.data[:fee_report][:channel_fees].first.base_fee_msat
          )

          @rate = Rate.new(
            parts_per_million: channel.data[:fee_report][:channel_fees].first.fee_per_mil
          )
        else
          @base = Satoshis.new(milisatoshis: policy.data.fee_base_msat)

          @rate = Rate.new(parts_per_million: policy.data.fee_rate_milli_msat)
        end
      end

      def to_h
        {
          base: @base.to_h,
          rate: @rate.to_h
        }
      end
    end
  end
end
