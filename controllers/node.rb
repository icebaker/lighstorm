# frozen_string_literal: true

require_relative './node/myself'
require_relative './node/all'
require_relative './node/find_by_public_key'

module Lighstorm
  module Controllers
    module Node
      def self.myself
        Myself.model(Myself.data)
      end

      def self.all(limit: nil)
        All.model(All.data(limit: limit))
      end

      def self.find_by_public_key(public_key)
        FindByPublicKey.model(FindByPublicKey.data(public_key))
      end

      def self.adapt(dump: nil, gossip: nil)
        Models::Node.adapt(dump: dump, gossip: gossip)
      end
    end
  end
end
