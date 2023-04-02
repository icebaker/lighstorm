# frozen_string_literal: true

require 'digest'

module Lighstorm
  module Adapter
    module Bitcoin
      class Address
        def self.new_address(grpc)
          {
            _source: :new_address,
            _key: Digest::SHA256.hexdigest([grpc[:address]].join('/')),
            code: grpc[:address]
          }
        end
      end
    end
  end
end
