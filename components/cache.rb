# frozen_string_literal: true

require 'singleton'

require 'zache'

module Lighstorm
  class Cache
    include Singleton

    attr_writer :config, :middleware

    def self.for(...)
      instance.for(...)
    end

    def initialize
      @client = Zache.new
    end

    def for(key, ttl: 1, params: {}, &block)
      key = build_key_for(key, params)

      @client.get(key, lifetime: ttl) do
        block.call
      end
    end

    def build_key_for(key, params)
      return key unless params.size.positive?

      key_params = []
      params.keys.sort.each do |param_key|
        key_params << "#{param_key}:#{params[param_key]}"
      end
      "#{key}/#{key_params.sort.join(',')}"
    end
  end
end
