# frozen_string_literal: true

module Lighstorm
  module Controller
    module Action
      Output = Struct.new(:data) do
        def request
          data[:request]
        end

        def response
          data[:response]
        end

        def result
          data[:result]
        end

        def to_h
          {
            request: request,
            response: response,
            result: result.to_h
          }
        end
      end
    end
  end
end
