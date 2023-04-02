# frozen_string_literal: true

require_relative '../../controllers/lightning/secret/valid_proof'

require 'digest'

module Lighstorm
  module Model
    module Lightning
      class Secret
        attr_reader :proof, :hash

        def self.generate
          data = { proof: SecureRandom.hex(32) }
          data[:hash] = Digest::SHA256.hexdigest([data[:proof]].pack('H*'))
          data
        end

        def self.create(components = nil, &vcr)
          data = vcr.nil? ? generate : vcr.call(-> { generate })

          Secret.new(data, components)
        end

        def initialize(data, components)
          @data = data
          @components = components

          @proof = data[:proof]
          @hash = data[:hash]
        end

        def preimage
          @proof
        end

        def valid_proof?(candidate_proof, &vcr)
          raise MissingComponentsError if @components.nil?

          return true if proof && proof.size == 64 && candidate_proof == proof

          Controller::Lightning::Secret::ValidProof.data(
            @components,
            @hash, candidate_proof, &vcr
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
end
