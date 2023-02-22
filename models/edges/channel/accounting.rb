# frozen_string_literal: true

require_relative '../../satoshis'
require_relative '../../errors'

module Lighstorm
  module Models
    class ChannelAccounting
      def initialize(data, is_mine)
        @data = data
        @is_mine = is_mine
      end

      def capacity
        @capacity ||= if @data[:capacity]
                        Satoshis.new(
                          milisatoshis: @data[:capacity][:milisatoshis]
                        )
                      end
      end

      def sent
        raise Errors::NotYourChannelError unless @is_mine

        @sent ||= if @data[:sent]
                    Satoshis.new(
                      milisatoshis: @data[:sent][:milisatoshis]
                    )
                  end
      end

      def received
        raise Errors::NotYourChannelError unless @is_mine

        @received ||= if @data[:received]
                        Satoshis.new(
                          milisatoshis: @data[:received][:milisatoshis]
                        )
                      end
      end

      def unsettled
        raise Errors::NotYourChannelError unless @is_mine

        @unsettled ||= if @data[:unsettled]
                         Satoshis.new(
                           milisatoshis: @data[:unsettled][:milisatoshis]
                         )
                       end
      end

      def to_h
        if @is_mine
          {
            capacity: capacity.to_h,
            sent: sent.to_h,
            received: received.to_h,
            unsettled: unsettled.to_h
          }
        else
          {
            capacity: capacity.to_h
          }
        end
      end
    end
  end
end
