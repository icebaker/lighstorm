# frozen_string_literal: true

require 'json'

require_relative '../../../../controllers/lightning/secret/valid_proof'
require_relative '../../../../controllers/lightning/secret'

RSpec.describe Lighstorm::Controller::Lightning::Secret::ValidProof do
  context 'amp invoice' do
    let(:secret_hash) { '4f5d4865ebcf184c5ab5c5e11e8fb5a0f6abd07776b4d976049a550a73074f3b' }

    context 'valid' do
      let(:proof) { 'c002966431351cda0f61e94aa98bb1999954d6b4ed72c5589942aace28f2e993' }

      it 'models' do
        valid_proof = described_class.data(
          Lighstorm::Controller::Lightning::Secret.components,
          secret_hash, proof
        ) do |fetch|
          VCR.tape.unsafe('I_KNOW_WHAT_I_AM_DOING').replay("Lighstorm::Controller::Lightning::Secret::ValidProof/#{secret_hash}") do
            fetch.call
          end
        end

        expect(valid_proof).to be(true)
      end
    end

    context 'invalid' do
      let(:proof) { '9055bfe1b1f37893efac8fe68d885cf3cb9d8cdf432fee3b3f5693b7dffb4000' }

      it 'models' do
        valid_proof = described_class.data(
          Lighstorm::Controller::Lightning::Secret.components,
          secret_hash, proof
        ) do |fetch|
          VCR.tape.unsafe('I_KNOW_WHAT_I_AM_DOING').replay("Lighstorm::Controller::Lightning::Secret::ValidProof/#{secret_hash}") do
            fetch.call
          end
        end

        expect(valid_proof).to be(false)
      end
    end
  end

  context 'non-amp invoice' do
    let(:secret_hash) { 'af6c2d05f3f9379ebbd5f25a4dcbc805ca683f2292816cde8b7331aea5b1725c' }

    context 'valid' do
      let(:proof) { '15b1201c30cef3b984aef4a47fb3106ad33516a021aa079766e8ac5fb84118d5' }

      it 'models' do
        valid_proof = described_class.data(
          Lighstorm::Controller::Lightning::Secret.components,
          secret_hash, proof
        ) do |fetch|
          VCR.tape.unsafe('I_KNOW_WHAT_I_AM_DOING').replay("Lighstorm::Controller::Lightning::Secret::ValidProof/#{secret_hash}") do
            fetch.call
          end
        end

        expect(valid_proof).to be(true)
      end
    end

    context 'invalid' do
      let(:proof) { 'be4de7af789e431a44200dbbd9776c50b86bd8720d40b403a3fbe603df6bd000' }

      it 'models' do
        valid_proof = described_class.data(
          Lighstorm::Controller::Lightning::Secret.components,
          secret_hash, proof
        ) do |fetch|
          VCR.tape.unsafe('I_KNOW_WHAT_I_AM_DOING').replay("Lighstorm::Controller::Lightning::Secret::ValidProof/#{secret_hash}") do
            fetch.call
          end
        end

        expect(valid_proof).to be(false)
      end
    end
  end
end
