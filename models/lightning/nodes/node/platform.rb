# frozen_string_literal: true

require_relative 'lightning'

require_relative '../../../../ports/grpc'
require_relative '../../../../adapters/lightning/nodes/node'

module Lighstorm
  module Model
    module Lightning
      class Platform
        attr_reader :data

        def initialize(node)
          @node = node
          @data = @node.data[:platform]
        end

        def blockchain
          @blockchain ||= @data ? @data[:blockchain] : nil
        end

        def network
          @network ||= @data ? @data[:network] : nil
        end

        def lightning
          @lightning ||= Lightning.new(@node)
        end

        def to_h
          response = {
            blockchain: blockchain,
            network: network
          }

          response[:lightning] = lightning.to_h if @node.myself?

          response
        end

        def dump
          data = Marshal.load(Marshal.dump(@data))
          data.merge(lightning: lightning.dump) if @node.myself?
          data
        end
      end
    end
  end
end
