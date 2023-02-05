# frozen_string_literal: true

require 'singleton'

require 'lnd-client'

module Lighstorm
  class LND
    include Singleton

    attr_writer :config, :middleware

    def initialize
      @config = nil
      @client = nil
      @middleware = ->(_key, &block) { block.call }
    end

    def middleware(key, &block)
      @middleware.call(key, &block)
    end

    def client
      return @client if @client

      raise 'missing credentials' if @config.nil? && ENV.fetch('LIGHSTORM_CERTIFICATE_PATH', nil).nil?

      @client = if @config
                  create_client_from_config
                else
                  create_client_from_environment_variables
                end

      @client.lightning(channel_args: { 'grpc.max_receive_message_length' => 1024 * 1024 * 50 })

      @client
    end

    def create_client_from_config
      LNDClient.new(
        socket_address: @config[:lnd_address],
        certificate_path: @config[:certificate_path],
        macaroon_path: @config[:macaroon_path]
      )
    end

    def create_client_from_environment_variables
      LNDClient.new(
        socket_address: ENV.fetch('LIGHSTORM_LND_ADDRESS', nil),
        certificate_path: ENV.fetch('LIGHSTORM_CERTIFICATE_PATH', nil),
        macaroon_path: ENV.fetch('LIGHSTORM_MACAROON_PATH', nil)
      )
    end
  end
end
