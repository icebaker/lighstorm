# frozen_string_literal: true

require_relative '../../satoshis'
require_relative 'channel_forwards/analysis'

module Lighstorm
  module Models
    class ChannelForwardsGroup
      attr_reader :_key, :last_at

      def initialize(data)
        @data = data

        @_key = data[:_key]
        @last_at = data[:last_at]
      end

      def analysis
        Analysis.new(@data[:analysis])
      end

      def channel
        @channel ||= Channel.new(@data[:channel])
      end

      def to_h
        {
          _key: _key,
          last_at: last_at,
          analysis: analysis.to_h,
          channel: channel.to_h
        }
      end
    end
  end
end
