# frozen_string_literal: true

require_relative '../../models/secret'

RSpec.describe Lighstorm::Models::Secret do
  let(:vcr_key) { 'Lighstorm::Models::Secret' }

  context 'generate' do
    let(:seed) { 'secret-a' }

    it 'generates' do
      secret = described_class.create do |generator|
        VCR.reel.unsafe('I_KNOW_WHAT_I_AM_DOING').replay("#{vcr_key}/#{seed}") do
          generator.call
        end
      end

      expect(secret.hash).to eq('e8e9440f4a2c4176d7b989297907bd47739ece78653fb701a183acfadef24bf5')
      expect(secret.preimage).to eq('c94fad20fc2c73817646a9fe2044882db8498f590951bd2e49b27e44a15a39a3')
      expect(secret.proof).to eq(secret.preimage)
      expect(secret.valid_proof?(secret.proof)).to be(true)
    end
  end

  context 'non-amp' do
    let(:secret_hash) { 'dee1416277ffbe611fc269f672b64d03419948a2a3ff6fbc9f14437d7dddd9b6' }
    let(:valid_proof) { 'd35a058b050919cd1eebe8de44d20f94d54ce8e00c7767429edce532c40ae9e9' }
    let(:invalid_proof) { 'd35a058b050919cd1eebe8de44d20f94d54ce8e00c7767429edce532c40ae000' }

    it 'generates' do
      secret = described_class.new(
        { hash: secret_hash, preimage: valid_proof }
      )

      expect(secret.hash).to eq(secret_hash)
      expect(secret.preimage).to eq(valid_proof)
      expect(secret.proof).to eq(secret.preimage)
      expect(
        secret.valid_proof?(valid_proof) do |fetch|
          VCR.reel.replay("#{vcr_key}/fetch/#{secret_hash}") { fetch.call }
        end
      ).to be(true)

      expect(
        secret.valid_proof?(invalid_proof) do |fetch|
          VCR.reel.replay("#{vcr_key}/fetch/#{secret_hash}") { fetch.call }
        end
      ).to be(false)
    end
  end

  context 'amp' do
    let(:secret_hash) { '4ac5053f182eddee1b252b129b5ade6225472e144f4067b9657e1fb022055714' }
    let(:valid_proof) { 'f59a4321f58b59eb764fb6345764f441b2923f622fb50843eaa6bf98fc9d4100' }
    let(:invalid_proof) { 'd35a058b050919cd1eebe8de44d20f94d54ce8e00c7767429edce532c40ae000' }

    it 'generates' do
      secret = described_class.new(
        { hash: secret_hash, preimage: nil }
      )

      expect(secret.hash).to eq(secret_hash)
      expect(secret.preimage).to be_nil
      expect(secret.proof).to eq(secret.preimage)
      expect(
        secret.valid_proof?(valid_proof) do |fetch|
          VCR.reel.replay("#{vcr_key}/fetch/#{secret_hash}") { fetch.call }
        end
      ).to be(true)

      expect(
        secret.valid_proof?(invalid_proof) do |fetch|
          VCR.reel.replay("#{vcr_key}/fetch/#{secret_hash}") { fetch.call }
        end
      ).to be(false)
    end
  end
end
