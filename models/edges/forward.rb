# frozen_string_literal: true

require 'digest'
require 'time'
require 'date'

require_relative '../satoshis'

require_relative '../connections/forward_channel'

module Lighstorm
  module Models
    class Forward
      KIND = :edge

      attr_reader :data

      def self.all(limit: nil)
        last_offset = 0

        forwards = []

        loop do
          response = LND.instance.middleware('lightning.forwarding_history') do
            LND.instance.client.lightning.forwarding_history(
              peer_alias_lookup: true, index_offset: last_offset
            )
          end

          response.forwarding_events.each { |raw_forward| forwards << raw_forward }

          # Unfortunately, forwards aren't sorted in descending order. :(
          # break if !limit.nil? && forwards.size >= limit

          break if last_offset == response.last_offset_index || last_offset > response.last_offset_index

          last_offset = response.last_offset_index
        end

        forwards = forwards.sort_by { |raw_forward| -raw_forward.timestamp_ns }

        forwards = forwards[0..limit - 1] unless limit.nil?

        forwards.map { |raw_forward| Forward.new(raw_forward) }
      end

      def self.first
        all(limit: 1).first
      end

      def self.last
        all.last
      end

      def initialize(raw)
        @data = { forwarding_history: { forwarding_events: [raw] } }
      end

      def id
        @id ||= Digest::SHA256.hexdigest(
          @data[:forwarding_history][:forwarding_events].first.timestamp_ns.to_s
        )
      end

      def at
        DateTime.parse(Time.at(@data[:forwarding_history][:forwarding_events].first.timestamp).to_s)
      end

      def fee
        Satoshis.new(milisatoshis: @data[:forwarding_history][:forwarding_events].first.fee_msat)
      end

      def in
        @in ||= ForwardChannel.new(:in, self)
      end

      def out
        @out ||= ForwardChannel.new(:out, self)
      end

      def to_h
        {
          id: id,
          at: at,
          fee: {
            milisatoshis: fee.milisatoshis,
            parts_per_million: fee.parts_per_million(self.in.amount.milisatoshis)
          },
          in: self.in.to_h,
          out: out.to_h
        }
      end

      def raw
        {
          forwarding_history: {
            forwarding_events: [@data[:forwarding_history][:forwarding_events].first.to_h]
          }
        }
      end
    end
  end
end
