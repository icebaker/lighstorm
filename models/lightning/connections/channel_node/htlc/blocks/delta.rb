# frozen_string_literal: true

require_relative '../../../../../concerns/protectable'

module Lighstorm
  module Model
    module Lightning
      class BlocksDelta
        include Protectable

        def initialize(data)
          @data = data
        end

        def minimum
          @minimum ||= @data[:minimum]
        end

        def to_h
          {
            minimum: minimum
          }
        end

        def dump
          Marshal.load(Marshal.dump(@data))
        end

        def minimum=(value)
          protect!(value)

          @minimum = value[:value]

          @data[:minimum] = @minimum

          minimum
        end
      end
    end
  end
end
