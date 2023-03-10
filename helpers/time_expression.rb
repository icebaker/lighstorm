# frozen_string_literal: true

require_relative '../models/errors'

module Lighstorm
  module Helpers
    module TimeExpression
      def self.seconds(expression)
        raise Errors::ArgumentError, 'missing keywords for time expression' unless expression.is_a?(Hash)

        duration = 0.0
        expression.each_key do |key|
          case key
          when :seconds
            duration += expression[key].to_f
          when :minutes
            duration += (expression[key].to_f * 60.0)
          when :hours
            duration += (expression[key].to_f * 60.0 * 60.0)
          when :days
            duration += (expression[key].to_f * 24.0 * 60.0 * 60.0)
          else
            raise Errors::ArgumentError, "unexpected keyword :#{key} for time expression #{expression}"
          end
        end

        raise Errors::ArgumentError, 'missing keywords for time expression' if expression.keys.empty?

        duration.to_i
      end
    end
  end
end
