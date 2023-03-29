# frozen_string_literal: true

require_relative '../controllers/secret/valid_proof'

require 'digest'

module Lighstorm
  module Models
    class Secret
      attr_reader :preimage, :hash

      def self.generate
        data = { preimage: SecureRandom.hex(32) }
        data[:hash] = Digest::SHA256.hexdigest([data[:preimage]].pack('H*'))
        data
      end

      def self.create(components = nil, &vcr)
        data = vcr.nil? ? generate : vcr.call(-> { generate })

        Secret.new(data, components)
      end

      def initialize(data, components)
        @data = data
        @components = components

        @preimage = data[:preimage]
        @hash = data[:hash]
      end

      def proof
        @preimage
      end

      def valid_proof?(candidate_preimage, &vcr)
        raise MissingComponentsError if @components.nil?

        return true if preimage && preimage.size == 64 && candidate_preimage == preimage

        Controllers::Secret::ValidProof.data(
          @components,
          @hash, candidate_preimage, &vcr
        )
      end

      def to_h
        {
          proof: proof,
          hash: hash
        }
      end
    end
  end
end
