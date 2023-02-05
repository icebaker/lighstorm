# frozen_string_literal: true

require_relative '../edges/channel'

module Lighstorm
  module Models
    class ForwardChannel
      KIND = :connection

      def initialize(direction, forward)
        @direction = direction
        @forward = forward
      end

      def channel
        @channel ||= if @direction == :in
                       Channel.find_by_id(
                         @forward.data[:forwarding_history][:forwarding_events].first.chan_id_in
                       )
                     else
                       Channel.find_by_id(
                         @forward.data[:forwarding_history][:forwarding_events].first.chan_id_out
                       )
                     end
      end

      def amount
        @amount ||= if @direction == :in
                      Satoshis.new(milisatoshis:
                        @forward.data[:forwarding_history][:forwarding_events].first.amt_in_msat)
                    else
                      Satoshis.new(milisatoshis:
                        @forward.data[:forwarding_history][:forwarding_events].first.amt_out_msat)
                    end
      end

      def to_h
        {
          amount: amount.to_h,
          channel: {
            id: channel.id,
            partner: {
              node: {
                alias: channel.partner&.node&.alias,
                public_key: channel.partner&.node&.public_key,
                color: channel.partner&.node&.color
              }
            }
          }
        }
      end
    end
  end
end
