# frozen_string_literal: true

require_relative 'mine'

require_relative '../../ports/grpc'
require_relative '../../adapters/edges/channel'
require_relative '../../adapters/nodes/node'
require_relative '../../adapters/connections/channel_node/fee'

module Lighstorm
  module Controllers
    module Channel
      module All
        def self.fetch(limit: nil)
          data = {
            at: Time.now,
            mine: Mine.fetch,
            describe_graph: Ports::GRPC.lightning.describe_graph.edges
          }

          data[:describe_graph] = data[:describe_graph][0..limit - 1] unless limit.nil?

          data
        end

        def self.adapt(raw)
          mine_adapted = Mine.adapt(raw[:mine])

          mine = mine_adapted[:list_channels].map do |data|
            Mine.transform(data, mine_adapted)
          end

          adapted = {
            mine: {},
            describe_graph: raw[:describe_graph].map do |raw_channel|
              Lighstorm::Adapter::Channel.describe_graph(raw_channel.to_h)
            end
          }

          mine.each do |channel|
            adapted[:mine][channel[:id]] = channel
          end

          adapted
        end

        def self.transform(data, adapted)
          return adapted[:mine][data[:id]] if adapted[:mine][data[:id]]

          data[:known] = true
          data[:mine] = false

          data[:partners].each do |partner|
            partner[:node][:platform] = {
              blockchain: adapted[:mine].first[1][:partners][0][:node][:platform][:blockchain],
              network: adapted[:mine].first[1][:partners][0][:node][:platform][:network]
            }
          end

          data
        end

        def self.data(limit: nil, &vcr)
          raw = vcr.nil? ? fetch(limit: limit) : vcr.call(-> { fetch(limit: limit) })

          adapted = adapt(raw)

          adapted[:describe_graph].map { |data| transform(data, adapted) }
        end

        def self.model(data)
          data.map do |node_data|
            Lighstorm::Models::Channel.new(node_data)
          end
        end
      end
    end
  end
end
