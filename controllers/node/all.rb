# frozen_string_literal: true

require_relative '../../ports/grpc'
require_relative '../../adapters/nodes/node'

module Lighstorm
  module Controllers
    module Node
      module All
        def self.fetch(components, limit: nil)
          data = {
            at: Time.now,
            get_info: components[:grpc].lightning.get_info.to_h,
            describe_graph: components[:grpc].lightning.describe_graph.nodes
          }

          data[:describe_graph] = data[:describe_graph][0..limit - 1] unless limit.nil?

          data
        end

        def self.adapt(raw)
          {
            get_info: Lighstorm::Adapter::Node.get_info(raw[:get_info]),
            describe_graph: raw[:describe_graph].map do |raw|
              Lighstorm::Adapter::Node.describe_graph(raw.to_h)
            end
          }
        end

        def self.transform(describe_graph, get_info)
          if get_info[:public_key] == describe_graph[:public_key]
            get_info.merge(myself: true)
          else
            describe_graph.merge(
              platform: {
                blockchain: get_info[:platform][:blockchain],
                network: get_info[:platform][:network]
              },
              myself: false
            )
          end
        end

        def self.data(components, limit: nil, &vcr)
          raw = if vcr.nil?
                  fetch(components, limit: limit)
                else
                  vcr.call(-> { fetch(components, limit: limit) })
                end

          adapted = adapt(raw)

          adapted[:describe_graph].map do |data|
            transform(data, adapted[:get_info])
          end
        end

        def self.model(data)
          data.map do |node_data|
            Lighstorm::Models::Node.new(node_data)
          end
        end
      end
    end
  end
end
