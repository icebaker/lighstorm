# frozen_string_literal: true

require_relative '../../ports/grpc'

module Lighstorm
  module Controllers
    module Impersonatable
      class DSL
        attr_reader :components

        def initialize(components = nil)
          @components = components.nil? ? { grpc: Ports::GRPC } : components
        end
      end

      def as(id)
        self::DSL.new({ grpc: Ports::GRPC::Impersonatable.new(id) })
      end

      def method_missing(method_name, *args, &block)
        if args.size == 1 && args.first.is_a?(Hash)
          self::DSL.new.send(method_name, **args.first, &block)
        else
          self::DSL.new.send(method_name, *args, &block)
        end
      end

      def respond_to_missing?(method_name, include_private = false)
        self::DSL.method_defined?(method_name) || super
      end
    end
  end
end
