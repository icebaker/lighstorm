# frozen_string_literal: true

require 'time'
require 'date'

require_relative '../../ports/grpc'
require_relative '../../adapters/edges/channel'

require_relative '../../components/lnd'
require_relative '../../components/cache'

require_relative '../nodes/node'
require_relative 'channel/accounting'

require_relative '../connections/channel_node'
require_relative '../satoshis'

require_relative '../errors'

module Lighstorm
  module Models
    class Channel
      attr_reader :data, :_key, :id, :opened_at, :up_at, :active, :exposure

      def initialize(data)
        @data = data

        @_key = data[:_key]
        @id = data[:id]
      end

      def known?
        @data[:known] == true
      end

      def mine?
        ensure_known!

        @data[:mine]
      end

      def exposure
        ensure_known!

        @data[:exposure]
      end

      def opened_at
        ensure_mine!

        @data[:opened_at]
      end

      def up_at
        ensure_mine!

        @data[:up_at]
      end

      def active
        ensure_mine!

        @data[:active]
      end

      def accounting
        ensure_known!

        @accounting ||= @data[:accounting] ? ChannelAccounting.new(@data[:accounting], mine?) : nil
      end

      def partners
        @partners ||= if @data[:partners]
                        @data[:partners].map do |data|
                          ChannelNode.new(data, known? ? mine? : nil, transaction)
                        end
                      else
                        []
                      end
      end

      def myself
        ensure_mine!

        @myself ||= partners.find { |partner| partner.node.myself? }
      end

      def partner
        ensure_mine!

        @partner ||= partners.find { |partner| !partner.node.myself? }
      end

      def transaction
        Struct.new(:data) do
          def funding
            Struct.new(:data) do
              def id
                data[:id]
              end

              def index
                data[:index]
              end

              def to_h
                { id: id, index: index }
              end
            end.new(data[:funding])
          end

          def to_h
            { funding: funding.to_h }
          end
        end.new(@data[:transaction])
      end

      def to_h
        if !known? && partners.size.positive?
          { _key: _key, id: id, partners: partners.map(&:to_h) }
        elsif !known?
          { _key: _key, id: id }
        elsif mine?
          {
            _key: _key,
            id: id,
            opened_at: opened_at,
            up_at: up_at,
            active: active,
            exposure: exposure,
            accounting: accounting.to_h,
            partner: partner.to_h,
            myself: myself.to_h
          }
        elsif @data[:accounting]
          {
            _key: _key,
            id: id,
            accounting: accounting.to_h,
            partners: partners.map(&:to_h)
          }
        else
          {
            _key: _key,
            id: id,
            partners: partners.map(&:to_h)
          }
        end
      end

      private

      def ensure_known!
        raise Errors::UnknownChannelError unless known?
      end

      def ensure_mine!
        ensure_known!
        raise Errors::NotYourChannelError if @data[:mine] == false
      end
    end
  end
end
