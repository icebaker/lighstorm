# frozen_string_literal: true

require 'digest'
require 'time'
require 'date'

require_relative '../satoshis'

require_relative '../connections/forward_channel'
require_relative 'groups/channel_forwards'

module Lighstorm
  module Models
    class Forward
      KIND = :edge

      attr_reader :data

      def self.all(limit: nil, raw: false, info: true)
        last_offset = 0

        forwards = []

        loop do
          response = Cache.for(
            'lightning.forwarding_history',
            params: { peer_alias_lookup: true, index_offset: last_offset }
          ) do
            LND.instance.middleware('lightning.forwarding_history') do
              LND.instance.client.lightning.forwarding_history(
                peer_alias_lookup: true, index_offset: last_offset
              )
            end
          end

          response.forwarding_events.each { |raw_forward| forwards << raw_forward }

          # Unfortunately, forwards aren't sorted in descending order. :(
          # break if !limit.nil? && forwards.size >= limit

          break if last_offset == response.last_offset_index || last_offset > response.last_offset_index

          last_offset = response.last_offset_index
        end

        forwards = forwards.sort_by { |raw_forward| -raw_forward.timestamp_ns }

        forwards = forwards[0..limit - 1] unless limit.nil?

        return forwards if raw

        forwards.map { |raw_forward| Forward.new(raw_forward, respond_info: info) }
      end

      def self.first
        all(limit: 1).first
      end

      def self.last
        all.last
      end

      def self.group_by_channel(direction: :out, hours_ago: nil, limit: nil, info: true)
        raw_forwards = all(raw: true)

        direction = direction.to_sym

        groups = {}

        raw_forwards.each do |raw_forward|
          channel_id = direction == :in ? raw_forward.chan_id_in : raw_forward.chan_id_out

          if hours_ago
            forward_hours_ago = (
              Time.now - Time.at(raw_forward.timestamp_ns / 1e+9)
            ).to_f / 3600

            next if forward_hours_ago > hours_ago
          end

          unless groups[channel_id]
            groups[channel_id] = {
              last_at: nil,
              analysis: { count: 0, sums: { amount: 0, fee: 0 } },
              direction => { id: channel_id }
            }
          end

          groups[channel_id][:analysis][:count] += 1
          groups[channel_id][:analysis][:sums][:amount] += raw_forward.amt_in_msat
          groups[channel_id][:analysis][:sums][:fee] += raw_forward.fee_msat

          if groups[channel_id][:last_at].nil? || raw_forward.timestamp_ns > groups[channel_id][:last_at]
            groups[channel_id][:last_at] = raw_forward.timestamp_ns
            groups[channel_id][:sample] = raw_forward
          end
        end

        groups = groups.values.sort_by { |group| - group[:last_at] }
                       .sort_by { |group| - group[:analysis][:count] }

        groups = groups[0..limit - 1] unless limit.nil?

        groups.map { |raw_group| ChannelForwardsGroup.new(direction, raw_group) }
      end

      def initialize(raw, respond_info: true)
        @respond_info = respond_info
        @data = { forwarding_history: { forwarding_events: [raw] } }
      end

      def id
        @id ||= Digest::SHA256.hexdigest(
          @data[:forwarding_history][:forwarding_events].first.timestamp_ns.to_s
        )
      end

      def at
        DateTime.parse(Time.at(
          @data[:forwarding_history][:forwarding_events].first.timestamp_ns / 1e+9
        ).to_s)
      end

      def fee
        Satoshis.new(milisatoshis: @data[:forwarding_history][:forwarding_events].first.fee_msat)
      end

      def in
        @in ||= ForwardChannel.new(:in, self, respond_info: @respond_info)
      end

      def out
        @out ||= ForwardChannel.new(:out, self, respond_info: @respond_info)
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
