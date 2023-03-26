# frozen_string_literal: true

require 'singleton'

require 'zache'

require_relative '../static/cache'
require_relative '../ports/dsl/lighstorm/errors'

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

    def safety_key(key)
      key.gsub('.', '_').sub(/^\[.*\]:/, '').to_sym
    end

    def for(key, ttl: nil, params: {}, &block)
      if ttl.nil?
        safety_key = self.safety_key(key)
        ttl = Lighstorm::Static::CACHE[safety_key]
        raise MissingTTLError, "missing ttl for #{safety_key} static/cache.rb" if ttl.nil?

        ttl = ttl == false ? false : ttl[:ttl]
      end

      if ttl == false
        block.call
      else
        key = build_key_for(key, params)
        @client.get(key, lifetime: ttl) do
          block.call
        end
      end
    end

    def build_key_for(key, params)
      return key unless !params.nil? && params.size.positive?

      key_params = []
      params.keys.sort.each do |param_key|
        key_params << "#{param_key}:#{params[param_key]}"
      end
      "#{key}/#{key_params.sort.join(',')}"
    end
  end
end
