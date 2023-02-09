# frozen_string_literal: true

require_relative '../edges/channel'
require_relative '../nodes/node'

module Lighstorm
  module Models
    class PaymentChannel
      KIND = :connection

      def initialize(raw_hop, hop_index, respond_info: true)
        @respond_info = respond_info
        @raw_hop = raw_hop
        @hop = hop_index
      end

      attr_reader :hop

      def channel
        Channel.find_by_id(@raw_hop.chan_id)
      end

      def amount
        @amount ||= Satoshis.new(milisatoshis: @raw_hop.amt_to_forward_msat)
      end

      def fee
        @fee ||= Satoshis.new(milisatoshis: @raw_hop.fee_msat)
      end

      def raw
        @raw_hop
      end

      def partner_node
        Node.find_by_public_key(@raw_hop.pub_key)
      end

      def to_h
        response = {
          hop: hop,
          amount: amount.to_h,
          fee: {
            milisatoshis: fee.milisatoshis,
            parts_per_million: fee.parts_per_million(amount.milisatoshis)
          },
          channel: {
            id: @raw_hop.chan_id.to_s,
            node: {
              public_key: @raw_hop.pub_key
            }
          }
        }

        return response unless @respond_info

        response[:channel] = {
          id: channel.id,
          partner: {
            node: {
              alias: partner_node&.alias,
              public_key: partner_node&.public_key,
              color: partner_node&.color
            }
          }
        }

        response
      end
    end
  end
end
