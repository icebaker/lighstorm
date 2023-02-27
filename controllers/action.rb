# frozen_string_literal: true

module Lighstorm
  module Controllers
    module Action
      Output = Struct.new(:data) do
        def response
          data[:response]
        end

        def result
          data[:result]
        end

        def to_h
          {
            response: response,
            result: result.to_h
          }
        end
      end
    end
  end
end
