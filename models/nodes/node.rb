# frozen_string_literal: true

require_relative '../../components/lnd'

require_relative '../edges/channel'

require_relative 'node/platform'

module Lighstorm
  module Models
    class Node
      KIND = :node

      attr_reader :alias, :public_key, :color

      def self.myself
        response = Cache.for('lightning.get_info') do
          LND.instance.middleware('lightning.get_info') do
            LND.instance.client.lightning.get_info
          end
        end

        Node.find_by_public_key(response.identity_pubkey, myself: true)
      end

      def self.find_by_public_key(public_key, myself: false)
        Node.new({ public_key: public_key }, myself: myself)
      end

      def self.all
        response = LND.instance.middleware('lightning.describe_graph') do
          LND.instance.client.lightning.describe_graph
        end

        myself_public_key = myself.public_key

        response.nodes.map do |raw_node|
          Node.new({ describe_graph: raw_node }, myself: raw_node.pub_key == myself_public_key)
        end
      end

      def myself?
        @myself
      end

      def platform
        @platform ||= Platform.new(self)
      end

      def channels
        if myself?
          Channel.mine
        else
          Channel.all
        end
      end

      def raw
        {
          get_node_info: @data[:get_node_info].to_h,
          describe_graph: @data[:describe_graph].to_h
        }
      end

      def to_h
        if (@data[:get_node_info] || @data[:describe_graph]) && myself?
          {
            alias: @alias,
            public_key: @public_key,
            color: @color,
            platform: platform.to_h
          }
        elsif @data[:get_node_info] || @data[:describe_graph]
          {
            alias: @alias,
            public_key: @public_key,
            color: @color
          }
        else
          {
            public_key: @public_key
          }
        end
      end

      def myself
        return @myself unless @myself.nil?

        response_get_info = Cache.for('lightning.get_info') do
          LND.instance.middleware('lightning.get_info') do
            LND.instance.client.lightning.get_info
          end
        end

        @myself = public_key == response_get_info.identity_pubkey
      end

      def error?
        !@data[:error].nil?
      end

      def error
        @data[:error]
      end

      def initialize(params, myself: false, fetch: true)
        if params[:public_key] && fetch
          begin
            response = Cache.for('lightning.get_node_info', params: { pub_key: params[:public_key] }) do
              LND.instance.middleware('lightning.get_node_info') do
                LND.instance.client.lightning.get_node_info(pub_key: params[:public_key])
              end
            end

            @data = { get_node_info: response }
            @raw_node = response.node
          rescue StandardError => e
            @data = { get_node_info: nil, error: e }
            @public_key = params[:public_key]
          end
        elsif params[:describe_graph]
          @data = { describe_graph: params[:describe_graph] }

          @raw_node = params[:describe_graph]
        else
          @data = {}
        end

        @myself = myself

        if params[:public_key] && !fetch
          @public_key = params[:public_key]
          return
        end

        @myself = myself

        return unless @raw_node

        @alias = @raw_node.alias
        @public_key = @raw_node.pub_key
        @color = @raw_node.color
      end
    end
  end
end
