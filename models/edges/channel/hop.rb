# frozen_string_literal: true

require_relative '../channel'

module Lighstorm
  module Models
    class HopChannel < Channel
      def initialize(data, payment)
        @hop_data = data
        @payment = payment
        super(data[:channel], nil)
      end

      def target
        partners.find do |partner|
          partner.node.public_key == @hop_data[:channel][:target][:public_key]
        end.node
      end

      def exit
        @exit ||= if include_myself? && @hop_data[:hop] == 1
                    partners.reverse.find do |partner|
                      !partner.node.myself?
                    end.node
                  elsif @hop_data[:hop] == 1
                    target
                  end
      end

      def entry
        return nil if @hop_data[:is_last] && @hop_data[:hop] == 1

        @entry ||= if include_myself? && @hop_data[:is_last]
                     if partners.size > 1
                       partners.reverse.find do |partner|
                         !partner.node.myself?
                       end.node
                     else
                       @payment.hops[@payment.hops.size - 2].channel.target
                     end
                   end
      end

      def include_myself?
        !partners.find { |partner| partner.node.myself? }.nil?
      end

      def to_h
        if !known? && !partners.size.positive?
          { _key: _key, id: id }
        else
          target_hash = target.to_h
          target_hash.delete(:platform)

          result = { _key: _key, id: id, target: target_hash }

          result[:entry] = entry.to_h if entry
          result[:exit] = self.exit.to_h if self.exit

          result
        end
      end
    end
  end
end
