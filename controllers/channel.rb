# frozen_string_literal: true

require_relative './channel/mine'
require_relative './channel/all'
require_relative './channel/find_by_id'

module Lighstorm
  module Controllers
    module Channel
      def self.components
        { grpc: Ports::GRPC }
      end

      def self.mine
        Mine.model(Mine.data(components))
      end

      def self.all(limit: nil)
        All.model(All.data(components, limit: limit))
      end

      def self.find_by_id(id)
        FindById.model(FindById.data(components, id))
      end

      def self.adapt(dump: nil, gossip: nil)
        Models::Channel.adapt(dump: dump, gossip: gossip)
      end
    end
  end
end
