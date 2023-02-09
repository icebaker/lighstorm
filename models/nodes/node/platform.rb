# frozen_string_literal: true

require_relative '../../../components/lnd'

require_relative 'lightning'

module Lighstorm
  module Models
    class Platform
      attr_reader :data

      def initialize(node)
        @node = node

        response = Cache.for('lightning.get_info') do
          LND.instance.middleware('lightning.get_info') do
            LND.instance.client.lightning.get_info
          end
        end

        @data = { get_info: response }
      end

      def blockchain
        @blockchain ||= @data[:get_info].chains.first.chain
      end

      def network
        @network ||= @data[:get_info].chains.first.network
      end

      def lightning
        @lightning ||= Lightning.new(self, @node)
      end

      def to_h
        response = {
          blockchain: blockchain,
          network: network
        }

        response[:lightning] = lightning.to_h if @node.myself?

        response
      end
    end
  end
end
