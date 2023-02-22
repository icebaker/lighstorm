# frozen_string_literal: true

require_relative '../../ports/grpc'
require_relative '../../adapters/nodes/node'

module Lighstorm
  module Controllers
    module Node
      module Myself
        def self.fetch
          {
            at: Time.now,
            get_info: Ports::GRPC.lightning.get_info.to_h
          }
        end

        def self.adapt(raw)
          { get_info: Lighstorm::Adapter::Node.get_info(raw[:get_info]) }
        end

        def self.data(&vcr)
          raw = vcr.nil? ? fetch : vcr.call(-> { fetch })

          adapted = adapt(raw)
          adapted[:get_info].merge(myself: true)
        end

        def self.model(data)
          Lighstorm::Models::Node.new(data)
        end
      end
    end
  end
end
