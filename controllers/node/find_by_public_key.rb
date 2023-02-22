# frozen_string_literal: true

require_relative '../../ports/grpc'
require_relative '../../adapters/nodes/node'

module Lighstorm
  module Controllers
    module Node
      module FindByPublicKey
        def self.fetch(public_key)
          {
            at: Time.now,
            get_info: Ports::GRPC.lightning.get_info.to_h,
            get_node_info: Ports::GRPC.lightning.get_node_info(pub_key: public_key).to_h
          }
        end

        def self.adapt(raw)
          {
            get_info: Lighstorm::Adapter::Node.get_info(raw[:get_info]),
            get_node_info: Lighstorm::Adapter::Node.get_node_info(raw[:get_node_info])
          }
        end

        def self.data(public_key, &vcr)
          raw = vcr.nil? ? fetch(public_key) : vcr.call(-> { fetch(public_key) })

          adapted = adapt(raw)

          if adapted[:get_info][:public_key] == adapted[:get_node_info][:public_key]
            adapted[:get_info].merge(myself: true)
          else
            adapted[:get_node_info].merge(
              platform: {
                blockchain: adapted[:get_info][:platform][:blockchain],
                network: adapted[:get_info][:platform][:network]
              },
              myself: false
            )
          end
        end

        def self.model(data)
          Lighstorm::Models::Node.new(data)
        end
      end
    end
  end
end
