# frozen_string_literal: true

require 'digest'

module Lighstorm
  module Models
    class Secret
      attr_reader :preimage, :hash

      def self.create
        data = { preimage: SecureRandom.hex(32) }
        data[:hash] = Digest::SHA256.hexdigest([data[:preimage]].pack('H*'))
        Secret.new(data)
      end

      def initialize(data)
        @data = data

        @preimage = data[:preimage]
        @hash = data[:hash]
      end

      def to_h
        {
          preimage: preimage,
          hash: hash
        }
      end
    end
  end
end
