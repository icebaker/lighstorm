# frozen_string_literal: true

module Lighstorm
  module Model
    module Protectable
      def prepare_token!(token)
        @token = token
      end

      def protect!(value)
        validate_token!(value)
      end

      def validate_token!(value)
        token = value.is_a?(Hash) ? value[:token] : nil

        raise OperationNotAllowedError if token.nil? || @token.nil? || token != @token

        @token = nil
      end
    end
  end
end
