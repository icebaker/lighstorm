# frozen_string_literal: true

require 'time'

require_relative '../../satoshis'

require_relative '../connections/payment_channel'
require_relative '../nodes/node'
require_relative '../invoice'
require_relative '../secret'

module Lighstorm
  module Model
    module Lightning
      class Payment
        attr_reader :_key, :at, :state, :secret, :purpose, :through, :message

        def initialize(data, components)
          @data = data
          @components = components

          @_key = data[:_key]
          @at = data[:at]
          @state = data[:state]
          @purpose = data[:purpose]
          @through = data[:through]
          @message = data[:message]
        end

        def how
          @how ||= spontaneous? ? 'spontaneously' : 'with-invoice'
        end

        def invoice
          @invoice ||= !spontaneous? && @data[:invoice] ? Invoice.new(@data[:invoice], @components) : nil
        end

        def amount
          @amount ||= @data[:amount] ? Satoshis.new(millisatoshis: @data[:amount][:millisatoshis]) : nil
        end

        def fee
          @fee ||= @data[:fee] ? Satoshis.new(millisatoshis: @data[:fee][:millisatoshis]) : nil
        end

        def secret
          @secret ||= @data[:secret] ? Secret.new(@data[:secret], @components) : nil
        end

        def hops
          return @hops if @hops
          return nil if @data[:hops].nil?

          @data[:hops].last[:is_last] = true
          @hops = @data[:hops].map do |hop|
            PaymentChannel.new(hop, self)
          end
        end

        def from
          @from ||= @data[:hops].nil? ? nil : hops.first
        end

        def to
          @to ||= @data[:hops].nil? ? nil : hops.last
        end

        def to_h
          response = {
            _key: _key,
            at: at,
            state: state,
            through: through,
            purpose: purpose,
            how: how,
            message: message,
            invoice: invoice&.to_h,
            from: from.to_h,
            to: to.to_h
          }

          response[:secret] = secret.to_h if secret
          response[:amount] = amount.to_h if amount
          if fee
            response[:fee] = {
              millisatoshis: fee.millisatoshis,
              parts_per_million: fee.parts_per_million(amount.millisatoshis)
            }
          end

          response[:hops] = hops.map(&:to_h) unless hops.nil?

          response
        end

        private

        def spontaneous?
          !@data[:invoice] || @data[:invoice][:code].nil?
        end
      end
    end
  end
end
