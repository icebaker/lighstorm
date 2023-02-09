# frozen_string_literal: true

require_relative '../../satoshis'
require_relative 'analysis'

module Lighstorm
  module Models
    class ChannelForwardsGroup
      def initialize(direction, data)
        @direction = direction
        @data = data
      end

      def last_at
        @last_at ||= DateTime.parse(Time.at(@data[:last_at].to_f / 1e+9).to_s)
      end

      def analysis
        Analysis.new(@data[:analysis])
      end

      def in
        return @in if @in

        raise raise ArgumentError, "Method `in` doesn't exist." unless @direction == :in

        @in = Channel.new({ id: @data[:in][:id] })
      end

      def out
        return @out if @out

        raise raise ArgumentError, "Method `out` doesn't exist." unless @direction == :out

        @out = Channel.new({ id: @data[:out][:id] })
      end

      # def capacity
      #   @capacity ||= Satoshis.new(milisatoshis: @channel.data[:get_chan_info].capacity * 1000)
      # end

      def to_h
        {
          last_at: last_at,
          analysis: analysis.to_h,
          @direction => {
            id: channel.id,
            partner: {
              node: {
                alias: channel&.partner&.node&.alias,
                public_key: channel&.partner&.node&.public_key,
                color: channel&.partner&.node&.color
              }
            }
          }
        }
      end

      private

      def channel
        @channel ||= @direction == :in ? self.in : out
      end
    end
  end
end
