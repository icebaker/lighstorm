# frozen_string_literal: true

require 'uri'

require_relative '../satoshis'
require_relative './address'

module Lighstorm
  module Model
    module Bitcoin
      class Request
        attr_reader :_key, :description, :message

        def initialize(data, components)
          @data = data
          @components = components

          @_key = @data[:_key]
          @description = @data[:description]
          @message = @data[:message]
        end

        def address
          @address ||= Address.new(@data[:address], @components)
        end

        def amount
          @amount ||= @data[:amount] ? Satoshis.new(millisatoshis: @data[:amount][:millisatoshis]) : nil
        end

        def uri
          return @uri unless @uri.nil?

          @uri = "bitcoin:#{address.code}"

          params = {}

          params[:amount] = amount.bitcoins if amount
          params[:label] = description if description
          params[:message] = message if message

          @uri = "#{@uri}?#{URI.encode_www_form(params)}" if params.keys.size.positive?

          @uri
        end

        def pay(
          fee:, required_confirmations: 6,
          amount: nil, description: nil,
          preview: false, &vcr
        )
          address.pay(
            amount: amount || self.amount.to_h,
            fee: fee,
            description: description || self.description,
            required_confirmations: required_confirmations,
            preview: preview, &vcr
          )
        end

        def to_h
          output = {
            _key: _key,
            address: address.to_h,
            uri: uri
          }

          output[:amount] = amount.to_h if amount
          output[:description] = description if description
          output[:message] = message if message

          output
        end
      end
    end
  end
end
