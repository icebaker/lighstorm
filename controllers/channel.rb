# frozen_string_literal: true

require_relative './channel/mine'
require_relative './channel/all'
require_relative './channel/find_by_id'

module Lighstorm
  module Controllers
    module Channel
      def self.mine
        Mine.model(Mine.data)
      end

      def self.all(limit: nil)
        All.model(All.data(limit: limit))
      end

      def self.find_by_id(id)
        FindById.model(FindById.data(id))
      end
    end
  end
end
