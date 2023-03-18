# frozen_string_literal: true

require 'securerandom'

require_relative '../../satoshis'
require_relative '../../rate'
require_relative '../../concerns/protectable'

require_relative '../../../components/lnd'
require_relative '../../../controllers/channel/actions/update_fee'

module Lighstorm
  module Models
    class Fee
      include Protectable

      def initialize(policy, data)
        @policy = policy
        @data = data
      end

      def base
        return nil unless @data[:base]

        @base ||= Satoshis.new(millisatoshis: @data[:base][:millisatoshis])
      end

      def rate
        return nil unless @data[:rate]

        @rate ||= Rate.new(parts_per_million: @data[:rate][:parts_per_million])
      end

      def to_h
        result = {}

        result[:base] = base.to_h if @data[:base]
        result[:rate] = rate.to_h if @data[:rate]

        return nil if result.empty?

        result
      end

      def dump
        Marshal.load(Marshal.dump(@data))
      end

      def components
        { grpc: Ports::GRPC }
      end

      def update(params, preview: false, &vcr)
        Controllers::Channel::UpdateFee.perform(
          components,
          @policy, @policy.transaction, params,
          preview: preview, &vcr
        )
      end

      def base=(value)
        protect!(value)

        @base = value[:value]

        @data[:base] = { millisatoshis: @base.millisatoshis }

        base
      end

      def rate=(value)
        protect!(value)

        @rate = value[:value]

        @data[:rate] = { parts_per_million: @rate.parts_per_million }

        rate
      end
    end
  end
end
