# frozen_string_literal: true

module Lighstorm
  module Ports
    class GRPCSession
      attr_reader :calls

      def initialize(grpc)
        @grpc = grpc
        @calls = {}
      end

      def handler(key, &block)
        @calls[key] = 0 unless @calls.key?(key)
        @calls[key] += 1
        block.call
      end

      def method_missing(method_name, *args)
        @grpc.send(method_name, *args) do |key, &block|
          handler(key, &block)
        end
      end
    end
  end
end
