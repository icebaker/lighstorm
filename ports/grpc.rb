# frozen_string_literal: true

require_relative '../components/cache'
require_relative '../components/lnd'
require_relative 'grpc/session'

module Lighstorm
  module Ports
    class GRPC
      def initialize(service, service_key, &handler)
        @service = service
        @service_key = service_key
        @handler = handler
      end

      def call!(call_key, *args, &block)
        key = "#{@service_key}.#{call_key}"

        if block.nil?
          response = Cache.for(key, params: args&.first) do
            LND.instance.middleware(key) do
              if @handler
                @handler.call(call_key) do
                  @service.send(call_key, *args, &block)
                end
              else
                @service.send(call_key, *args, &block)
              end
            end
          end
        else
          LND.instance.middleware(key) do
            if @handler
              @handler.call(call_key) do
                @service.send(call_key, *args, &block)
              end
            else
              @service.send(call_key, *args, &block)
            end
          end
        end
      end

      def method_missing(method_name, *args, &block)
        call_key = method_name.to_sym

        raise ArgumentError, "Method `#{method_name}` doesn't exist." unless @service.respond_to?(call_key)

        call!(call_key, *args, &block)
      end

      def respond_to_missing?(method_name, include_private = false)
        call_key = method_name.to_sym

        @service.respond_to?(call_key) || super
      end

      def self.session
        GRPCSession.new(self)
      end

      def self.method_missing(method_name, *_args, &block)
        service_key = method_name.to_sym

        unless LND.instance.client.respond_to?(service_key)
          raise ArgumentError,
                "Method `#{method_name}` doesn't exist."
        end

        new(LND.instance.client.send(service_key), service_key, &block)
      end

      def self.respond_to_missing?(method_name, include_private = false)
        service_key = method_name.to_sym

        LND.instance.client.respond_to?(service_key) || super
      end
    end
  end
end
