# frozen_string_literal: true

require_relative '../concerns/impersonatable'

module Lighstorm
  module Controller
    module Lightning
      module Secret
        extend Impersonatable

        class DSL < Impersonatable::DSL
        end
      end
    end
  end
end
