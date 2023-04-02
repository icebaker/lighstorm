# frozen_string_literal: true

require_relative '../../../models/lightning/secret'

RSpec.describe Lighstorm::Model::Lightning::Secret do
  let(:vcr_key) { 'Lighstorm::Model::Lightning::Secret' }

  context 'generate' do
    let(:seed) { 'secret-a' }

    it 'generates' do
      secret = described_class.create(Lighstorm::Controller::Lightning::Invoice.components) do |generator|
        VCR.reel.unsafe('I_KNOW_WHAT_I_AM_DOING').replay("#{vcr_key}/#{seed}") do
          generator.call
        end
      end

      expect(secret.hash).to eq('b895286f49e9c27ed5d5562450349deea015a924a4cacd90055d56ab8a1b8a24')
      expect(secret.proof).to eq('7eb224f88b173a190c68b340e6ffb8abb6590412470bd6ac5d8719f2ac276c89')
      expect(secret.preimage).to eq(secret.proof)
      expect(secret.valid_proof?(secret.proof)).to be(true)
    end
  end

  context 'non-amp' do
    let(:secret_hash) { 'af6c2d05f3f9379ebbd5f25a4dcbc805ca683f2292816cde8b7331aea5b1725c' }
    let(:valid_proof) { '15b1201c30cef3b984aef4a47fb3106ad33516a021aa079766e8ac5fb84118d5' }
    let(:invalid_proof) { 'd35a058b050919cd1eebe8de44d20f94d54ce8e00c7767429edce532c40ae000' }

    it 'generates' do
      secret = described_class.new(
        { hash: secret_hash, proof: valid_proof },
        Lighstorm::Controller::Lightning::Invoice.components
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
    let(:secret_hash) { 'a6b4513680d6a780bd6e952cafe206fa939485d4658dd8e3538995f76c94e4f7' }
    let(:valid_proof) { '5ec3ecee994f09e31934ba382723c7b18e9c6f513853b1020101c393d3267ab5' }
    let(:invalid_proof) { 'd35a058b050919cd1eebe8de44d20f94d54ce8e00c7767429edce532c40ae000' }

    it 'generates' do
      secret = described_class.new(
        { hash: secret_hash, proof: nil },
        Lighstorm::Controller::Lightning::Invoice.components
      )

      expect(secret.hash).to eq(secret_hash)
      expect(secret.preimage).to be_nil
      expect(secret.proof).to eq(secret.preimage)
      expect(
        secret.valid_proof?(valid_proof) do |fetch|
          VCR.reel.unsafe('I_KNOW_WHAT_I_AM_DOING').replay("#{vcr_key}/fetch/#{secret_hash}") { fetch.call }
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
