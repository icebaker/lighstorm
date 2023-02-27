# frozen_string_literal: true

require_relative '../../satoshis'
require_relative '../../errors'
require_relative '../../concerns/protectable'

module Lighstorm
  module Models
    class ChannelAccounting
      include Protectable

      def initialize(data, is_mine)
        @data = data
        @is_mine = is_mine
      end

      def capacity
        @capacity ||= if @data[:capacity]
                        Satoshis.new(
                          millisatoshis: @data[:capacity][:millisatoshis]
                        )
                      end
      end

      def sent
        raise Errors::NotYourChannelError unless @is_mine

        @sent ||= if @data[:sent]
                    Satoshis.new(
                      millisatoshis: @data[:sent][:millisatoshis]
                    )
                  end
      end

      def received
        raise Errors::NotYourChannelError unless @is_mine

        @received ||= if @data[:received]
                        Satoshis.new(
                          millisatoshis: @data[:received][:millisatoshis]
                        )
                      end
      end

      def unsettled
        raise Errors::NotYourChannelError unless @is_mine

        @unsettled ||= if @data[:unsettled]
                         Satoshis.new(
                           millisatoshis: @data[:unsettled][:millisatoshis]
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

      def dump
        Marshal.load(Marshal.dump(@data))
      end

      def capacity=(value)
        protect!(value)

        @capacity = value[:value]

        @data[:capacity][:millisatoshis] = @capacity.millisatoshis

        capacity
      end
    end
  end
end
