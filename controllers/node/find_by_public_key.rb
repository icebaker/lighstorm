# frozen_string_literal: true

require_relative '../../ports/grpc'
require_relative '../../adapters/nodes/node'

module Lighstorm
  module Controllers
    module Node
      module FindByPublicKey
        def self.fetch(components, public_key)
          {
            at: Time.now,
            get_info: components[:grpc].lightning.get_info.to_h,
            get_node_info: components[:grpc].lightning.get_node_info(pub_key: public_key).to_h
          }
        end

        def self.adapt(raw)
          {
            get_info: Lighstorm::Adapter::Node.get_info(raw[:get_info]),
            get_node_info: Lighstorm::Adapter::Node.get_node_info(raw[:get_node_info])
          }
        end

        def self.data(components, public_key, &vcr)
          raw = if vcr.nil?
                  fetch(components, public_key)
                else
                  vcr.call(-> { fetch(components, public_key) })
                end

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

        def self.model(data, components)
          Lighstorm::Models::Node.new(data, components)
        end
      end
    end
  end
end
