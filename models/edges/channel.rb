# frozen_string_literal: true

require 'time'
require 'date'

require_relative '../../components/lnd'
require_relative '../../components/cache'

require_relative '../nodes/node'
require_relative 'channel/accounting'

require_relative '../connections/channel_node'
require_relative '../satoshis'

module Lighstorm
  module Models
    class Channel
      KIND = :edge

      attr_reader :data

      def self.all
        response = LND.instance.middleware('lightning.describe_graph') do
          LND.instance.client.lightning.describe_graph
        end

        response.edges.map do |raw_channel|
          Channel.new({ describe_graph: raw_channel })
        end
      end

      def self.first
        all.first
      end

      def self.last
        all.last
      end

      def self.mine
        response = Cache.for('lightning.list_channels') do
          LND.instance.middleware('lightning.list_channels') do
            LND.instance.client.lightning.list_channels
          end
        end

        response.channels.map do |channel|
          Channel.find_by_id(channel.chan_id.to_s)
        end
      end

      def self.find_by_id(id)
        Channel.new({ id: id })
      end

      def id
        # Standard JSON don't support BigInt, so, a String is safer.
        @id.to_s
      end

      def initialize(params)
        if params[:id]
          begin
            response = Cache.for('lightning.get_chan_info', params: { chan_id: params[:id].to_i }) do
              LND.instance.middleware('lightning.get_chan_info') do
                LND.instance.client.lightning.get_chan_info(chan_id: params[:id].to_i)
              end
            end

            @data = { get_chan_info: response }
            @id = @data[:get_chan_info].channel_id
          rescue StandardError => e
            @data = { get_chan_info: nil, error: e }
            @id = params[:id]
          end
        elsif params[:describe_graph]
          @data = { describe_graph: params[:describe_graph] }
          @id = @data[:describe_graph].channel_id
        end

        fetch_from_fee_report!

        fetch_from_list_channels!
        calculate_times_after_list_channels!
      end

      def error?
        !@data[:error].nil?
      end

      def error
        @data[:error]
      end

      def active
        @data[:list_channels] ? @data[:list_channels][:channels].first.active : nil
      end

      def exposure
        return 'public' if @data[:describe_graph]

        return unless @data[:list_channels]

        @data[:list_channels][:channels].first.private ? 'private' : 'public'
      end

      def opened_at
        @opened_at ||= if @data[:list_channels]
                         DateTime.parse(
                           (Time.now - @data[:list_channels][:channels].first.lifetime).to_s
                         )
                       end
      end

      def up_at
        @up_at ||= if @data[:list_channels]
                     DateTime.parse(
                       (Time.now - @data[:list_channels][:channels].first.uptime).to_s
                     )
                   end
      end

      def accounting
        @accounting ||= ChannelAccounting.new(self)
      end

      def partners(fetch: false)
        @partners ||= if mine?
                        [myself, partner]
                      elsif @data[:describe_graph]
                        [
                          ChannelNode.new(
                            self,
                            Node.new({ public_key: @data[:describe_graph].node1_pub }, fetch: fetch)
                          ),
                          ChannelNode.new(
                            self,
                            Node.new({ public_key: @data[:describe_graph].node2_pub }, fetch: fetch)
                          )
                        ]
                      elsif @data[:get_chan_info]
                        [
                          ChannelNode.new(
                            self,
                            Node.new({ public_key: @data[:get_chan_info].node1_pub }, fetch: fetch)
                          ),
                          ChannelNode.new(
                            self,
                            Node.new({ public_key: @data[:get_chan_info].node2_pub }, fetch: fetch)
                          )
                        ]
                      else
                        raise 'missing data'
                      end
      end

      def mine?
        my_node = Node.myself.public_key

        if @data[:get_chan_info]
          (
            @data[:get_chan_info].node1_pub == my_node || @data[:get_chan_info].node2_pub == my_node
          )
        elsif @data[:describe_graph]
          (
            @data[:describe_graph].node1_pub == my_node || @data[:describe_graph].node2_pub == my_node
          )
        else
          false
        end
      end

      def myself
        raise 'not your channel' unless mine?

        @myself ||= ChannelNode.new(self, Node.myself)
      end

      def partner
        raise 'not your channel' unless mine?

        key = @data[:get_chan_info] ? :get_chan_info : :describe_graph

        public_key = if @data[key].node1_pub == myself.node.public_key
                       @data[key].node2_pub
                     else
                       @data[key].node1_pub
                     end

        @partner ||= ChannelNode.new(self, Node.find_by_public_key(public_key))
      end

      def raw
        {
          get_chan_info: @data[:get_chan_info].to_h,
          describe_graph: @data[:describe_graph].to_h,
          list_channels: {
            channels: @data[:list_channels] ? @data[:list_channels][:channels].map(&:to_h) : nil
          }
        }
      end

      def to_h
        if @data[:get_chan_info]
          {
            id: id,
            opened_at: opened_at,
            up_at: up_at,
            active: active,
            exposure: exposure,
            accounting: accounting.to_h,
            partner: partner.to_h,
            myself: myself.to_h
          }
        else
          {
            id: id,
            accounting: accounting.to_h,
            partners: partners.map(&:to_h)
          }
        end
      end

      private

      # Ensure that we are getting fresh up-date data about our own fees.
      def fetch_from_fee_report!
        response = Cache.for('lightning.fee_report') do
          LND.instance.middleware('lightning.fee_report') do
            LND.instance.client.lightning.fee_report
          end
        end

        response.channel_fees.map do |channel|
          if channel.chan_id == @id
            @data[:fee_report] = { channel_fees: [channel] }
            break
          end
        end
      end

      def fetch_from_list_channels!
        response = Cache.for('lightning.list_channels') do
          LND.instance.middleware('lightning.list_channels') do
            LND.instance.client.lightning.list_channels
          end
        end

        response.channels.map do |channel|
          if channel.chan_id == @id
            @data[:list_channels] = { channels: [channel] }
            break
          end
        end
      end

      def calculate_times_after_list_channels!
        opened_at
        up_at
      end
    end
  end
end
