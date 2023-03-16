# frozen_string_literal: true

require 'singleton'
require 'securerandom'
require 'lnd-client'

require_relative '../ports/dsl/lighstorm/errors'

module Lighstorm
  class LND
    include Singleton

    attr_writer :middleware

    def initialize
      @default_key = SecureRandom.hex
      @middleware = ->(_key, &block) { block.call }
    end

    def connect!(*params)
      if params.last.is_a?(Hash)
        unless params.last.key?(:lightning)
          params.last[:lightning] = {
            channel_args: { 'grpc.max_receive_message_length' => 1024 * 1024 * 50 }
          }
        end
      else
        params << {
          lightning: { channel_args: { 'grpc.max_receive_message_length' => 1024 * 1024 * 50 } }
        }
      end

      LNDClient.add_connection!(@default_key, *params)
    end

    def middleware(key, &block)
      @middleware.call(key, &block)
    end

    def client
      try_to_connect_from_environment_variables! unless LNDClient.connections.include?(@default_key)
      LNDClient.as(@default_key)
    end

    def create_client_from_config
      LNDClient.new(
        socket_address: @config[:lnd_address],
        certificate_path: @config[:certificate_path],
        macaroon_path: @config[:macaroon_path]
      )
    end

    def try_to_connect_from_environment_variables!
      return connect!(ENV.fetch('LIGHSTORM_LND_CONNECT')) if ENV.fetch('LIGHSTORM_LND_CONNECT', nil)

      params = {}

      raise MissingCredentialsError, 'missing credentials [address]' unless ENV.fetch('LIGHSTORM_LND_ADDRESS', nil)

      params[:address] = ENV.fetch('LIGHSTORM_LND_ADDRESS')

      if ENV.fetch('LIGHSTORM_LND_CERTIFICATE', nil)
        params[:certificate] = ENV.fetch('LIGHSTORM_LND_CERTIFICATE')
      elsif ENV.fetch('LIGHSTORM_LND_CERTIFICATE_PATH', nil)
        params[:certificate_path] = ENV.fetch('LIGHSTORM_LND_CERTIFICATE_PATH')
      else
        raise MissingCredentialsError, 'missing credentials [certificate]'
      end

      if ENV.fetch('LIGHSTORM_LND_MACAROON', nil)
        params[:macaroon] = ENV.fetch('LIGHSTORM_LND_MACAROON')
      elsif ENV.fetch('LIGHSTORM_LND_MACAROON_PATH', nil)
        params[:macaroon_path] = ENV.fetch('LIGHSTORM_LND_MACAROON_PATH')
      else
        raise MissingCredentialsError, 'missing credentials [macaroon]'
      end

      connect!(params)
    end
  end
end
