# frozen_string_literal: true

require 'securerandom'

require_relative '../../satoshis'
require_relative '../../rate'

require_relative '../../../components/lnd'
require_relative '../../../controllers/channel/actions/update_fee'

module Lighstorm
  module Models
    class Fee
      def initialize(policy, data)
        @policy = policy
        @data = data
      end

      def base
        @base ||= Satoshis.new(milisatoshis: @data[:base][:milisatoshis])
      end

      def rate
        @rate ||= Rate.new(parts_per_million: @data[:rate][:parts_per_million])
      end

      def to_h
        {
          base: base.to_h,
          rate: rate.to_h
        }
      end

      def update(params, preview: false, fake: false)
        Controllers::Channel::UpdateFee.perform(
          @policy, params, preview: preview, fake: fake
        )
      end

      def base=(value)
        validate_token!(value)

        @base = value[:value]
      end

      def rate=(value)
        validate_token!(value)

        @rate = value[:value]
      end

      def prepare_token!(token)
        @token = token
      end

      private

      def validate_token!(value)
        token = value.is_a?(Hash) ? value[:token] : nil

        raise OperationNotAllowedError if token.nil? || @token.nil? || token != @token

        @token = nil
      end
    end
  end
end
