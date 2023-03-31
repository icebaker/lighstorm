# frozen_string_literal: true

require 'digest'

module Lighstorm
  module Adapter
    class Bitcoin
      def self.new_address(grpc)
        {
          _source: :new_address,
          _key: Digest::SHA256.hexdigest([grpc[:at], grpc[:new_address][:address]].join('/')),
          at: grpc[:at],
          address: grpc[:new_address][:address]
        }
      end
    end
  end
end
