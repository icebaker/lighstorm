# frozen_string_literal: true

require_relative '../edges/channel'

module Lighstorm
  module Models
    class ForwardChannel
      KIND = :connection

      def initialize(direction, forward, respond_info: true)
        @respond_info = respond_info
        @direction = direction
        @forward = forward
      end

      def channel
        @channel ||= Channel.find_by_id(channel_id)
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
        response = {
          amount: amount.to_h,
          channel: { id: channel_id }
        }

        return response unless @respond_info

        response[:channel] = {
          id: channel.id,
          partner: {
            node: {
              alias: channel.partner&.node&.alias,
              public_key: channel.partner&.node&.public_key,
              color: channel.partner&.node&.color
            }
          }
        }

        response
      end

      private

      def channel_id
        if @direction == :in
          @forward.data[:forwarding_history][:forwarding_events].first.chan_id_in.to_s
        else
          @forward.data[:forwarding_history][:forwarding_events].first.chan_id_out.to_s
        end
      end
    end
  end
end
