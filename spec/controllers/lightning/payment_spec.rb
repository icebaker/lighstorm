# frozen_string_literal: true

require_relative '../../../controllers/lightning/payment'

RSpec.describe Lighstorm::Controller::Lightning::Payment do
  describe '.find_by_secret_hash' do
    let(:secret_hash) { '1b4dae91fef992af3d7506133d5f26b52b0d5f554555966c2c168ed59b2b2c7a' }

    it 'finds' do
      payment = described_class.find_by_secret_hash(secret_hash) do |fetch|
        VCR.tape.replay("Controller::Lightning::Payment.find_by_secret_hash/#{secret_hash}") do
          fetch.call
        end
      end

      expect(payment.secret.hash).to eq(secret_hash)
      expect(payment.secret.preimage.size).to eq(64)
      expect(payment.at.utc.to_s).to eq('2023-04-02 09:58:17 UTC')
      expect(payment.state).to eq('succeeded')
      expect(payment.amount.millisatoshis).to eq(1000)
      expect(payment.fee.millisatoshis).to eq(0)
      expect(payment.invoice.code).to eq('lnbcrt10n1pjzj5dgpp5rdx6ay07lxf270t4qcfn6hexk54s6h64g42evmpvz68dtxet93aqdq2gdhkven9v5cqzpgxqyz5vqsp5hsxfc3k09yaldwalyfluy2d7599t9exv2lx2wfp0r2ur8sltz96q9qyyssqjv42wywr7ffvyj4kc40y649hvnzkj5mhmmndyezlqsq7x63akyq3dpp43xt76ggqrxctx46g0z6l24n805lcp55h893lwqm5felch0cpve5p0c')
      expect(payment.invoice.description.memo).to eq('Coffee')
      expect(payment.invoice.amount.millisatoshis).to eq(1000)
      expect(payment.invoice.state).to be_nil
    end
  end

  describe '.find_by_invoice_code' do
    let(:invoice_code) do
      'lnbcrt10n1pjzj5dgpp5rdx6ay07lxf270t4qcfn6hexk54s6h64g42evmpvz68dtxet93aqdq2gdhkven9v5cqzpgxqyz5vqsp5hsxfc3k09yaldwalyfluy2d7599t9exv2lx2wfp0r2ur8sltz96q9qyyssqjv42wywr7ffvyj4kc40y649hvnzkj5mhmmndyezlqsq7x63akyq3dpp43xt76ggqrxctx46g0z6l24n805lcp55h893lwqm5felch0cpve5p0c'
    end

    it 'finds' do
      payment = described_class.find_by_invoice_code(invoice_code) do |fetch|
        VCR.tape.replay("Controller::Lightning::Payment.find_by_invoice_code/#{invoice_code}") do
          fetch.call
        end
      end

      expect(payment.secret.hash).to eq('1b4dae91fef992af3d7506133d5f26b52b0d5f554555966c2c168ed59b2b2c7a')
      expect(payment.secret.preimage.size).to eq(64)
      expect(payment.at.utc.to_s).to eq('2023-04-02 09:58:17 UTC')
      expect(payment.state).to eq('succeeded')
      expect(payment.amount.millisatoshis).to eq(1000)
      expect(payment.fee.millisatoshis).to eq(0)
      expect(payment.invoice.code).to eq(invoice_code)
      expect(payment.invoice.description.memo).to eq('Coffee')
      expect(payment.invoice.amount.millisatoshis).to eq(1000)
      expect(payment.invoice.state).to be_nil
    end
  end
end
