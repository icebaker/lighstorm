# frozen_string_literal: true

require 'time'

require_relative '../satoshis'

require_relative '../connections/payment_channel'
require_relative '../nodes/node'
require_relative '../payment_request'

module Lighstorm
  module Models
    class Payment
      attr_reader :_key, :hash, :request, :status, :created_at, :settled_at, :purpose

      def initialize(data)
        @data = data

        @_key = data[:_key]
        @status = data[:status]
        @created_at = data[:created_at]
        @settled_at = data[:settled_at]
        @purpose = data[:purpose]
      end

      def request
        @request ||= PaymentRequest.new(@data[:request])
      end

      def fee
        @fee ||= Satoshis.new(milisatoshis: @data[:fee][:milisatoshis])
      end

      def hops
        return @hops if @hops

        @data[:hops].last[:is_last] = true
        @hops = @data[:hops].map do |hop|
          PaymentChannel.new(hop, self)
        end
      end

      def from
        @from ||= hops.first
      end

      def to
        @to ||= hops.last
      end

      def to_h
        response = {
          _key: _key,
          status: status,
          created_at: created_at,
          settled_at: settled_at,
          purpose: purpose,
          fee: {
            milisatoshis: fee.milisatoshis,
            parts_per_million: fee.parts_per_million(request.amount.milisatoshis)
          },
          request: request.to_h,
          from: from.to_h,
          to: to.to_h,
          hops: hops.map(&:to_h)
        }
      end
    end
  end
end
