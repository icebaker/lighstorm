# frozen_string_literal: true

require_relative './concerns/impersonatable'

module Lighstorm
  module Controller
    module Connection
      def self.connect!(...)
        LND.instance.connect!(...)
      end

      def self.add!(...)
        LND.instance.add_connection!(...)
      end

      def self.all(...)
        LND.instance.connections(...)
      end

      def self.default(...)
        LND.instance.default(...)
      end

      def self.for(...)
        LND.instance.for(...)
      end

      def self.remove!(...)
        LND.instance.remove_connection!(...)
      end
    end
  end
end
