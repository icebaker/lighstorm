# frozen_string_literal: true

require 'json'

require_relative '../../../controllers/secret/valid_proof'

RSpec.describe Lighstorm::Controllers::Secret::ValidProof do
  context 'amp invoice' do
    let(:secret_hash) { '4ac5053f182eddee1b252b129b5ade6225472e144f4067b9657e1fb022055714' }

    context 'valid' do
      let(:proof) { '9055bfe1b1f37893efac8fe68d885cf3cb9d8cdf432fee3b3f5693b7dffb477f' }

      it 'models' do
        valid_proof = described_class.data(secret_hash, proof) do |fetch|
          VCR.tape.replay("Lighstorm::Controllers::Secret::ValidProof/#{secret_hash}") { fetch.call }
        end

        expect(valid_proof).to be(true)
      end
    end

    context 'invalid' do
      let(:proof) { '9055bfe1b1f37893efac8fe68d885cf3cb9d8cdf432fee3b3f5693b7dffb4000' }

      it 'models' do
        valid_proof = described_class.data(secret_hash, proof) do |fetch|
          VCR.tape.replay("Lighstorm::Controllers::Secret::ValidProof/#{secret_hash}") { fetch.call }
        end

        expect(valid_proof).to be(false)
      end
    end
  end

  context 'non-amp invoice' do
    let(:secret_hash) { 'dee1416277ffbe611fc269f672b64d03419948a2a3ff6fbc9f14437d7dddd9b6' }

    context 'valid' do
      let(:proof) { 'be4de7af789e431a44200dbbd9776c50b86bd8720d40b403a3fbe603df6bd7e8' }

      it 'models' do
        valid_proof = described_class.data(secret_hash, proof) do |fetch|
          VCR.tape.replay("Lighstorm::Controllers::Secret::ValidProof/#{secret_hash}") { fetch.call }
        end

        expect(valid_proof).to be(true)
      end
    end

    context 'invalid' do
      let(:proof) { 'be4de7af789e431a44200dbbd9776c50b86bd8720d40b403a3fbe603df6bd000' }

      it 'models' do
        valid_proof = described_class.data(secret_hash, proof) do |fetch|
          VCR.tape.replay("Lighstorm::Controllers::Secret::ValidProof/#{secret_hash}") { fetch.call }
        end

        expect(valid_proof).to be(false)
      end
    end
  end
end
