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
        response = Cache.for('lightning.get_info', ttl: 1) do
          LND.instance.middleware('lightning.get_info') do
            LND.instance.client.lightning.get_info
          end
        end

        Node.find_by_public_key(response.identity_pubkey, myself: true)
      end

      def self.find_by_public_key(public_key, myself: false)
        Node.new({ public_key: public_key }, myself: myself)
      end

      def myself?
        @myself
      end

      def platform
        @platform ||= Platform.new(self)
      end

      def channels
        raise 'cannot list channels from a node that is not yours' unless myself?

        Channel.all
      end

      def raw
        {
          get_node_info: @data[:get_node_info].to_h
        }
      end

      def to_h
        {
          alias: @alias,
          public_key: @public_key,
          color: @color,
          platform: platform.to_h
        }
      end

      private

      def initialize(params, myself: false)
        response = Cache.for(
          'lightning.get_node_info',
          ttl: 5 * 60, params: { pub_key: params[:public_key] }
        ) do
          LND.instance.middleware('lightning.get_node_info') do
            LND.instance.client.lightning.get_node_info(pub_key: params[:public_key])
          end
        end

        @data = { get_node_info: response }

        @myself = myself

        @alias = @data[:get_node_info].node.alias
        @public_key = @data[:get_node_info].node.pub_key
        @color = @data[:get_node_info].node.color
      end
    end
  end
end
