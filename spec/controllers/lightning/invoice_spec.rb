# frozen_string_literal: true

require_relative '../../../controllers/lightning/invoice'

RSpec.describe Lighstorm::Controller::Lightning::Invoice do
  describe '.find_by_secret_hash' do
    let(:secret_hash) { '530adc2e26970ed02b3438e8b23660ef68769fd506b2a1318a00838c996b3189' }

    it 'finds' do
      invoice = described_class.find_by_secret_hash(secret_hash) do |fetch|
        VCR.tape.replay("Controller::Lightning::Invoice.find_by_secret_hash/#{secret_hash}") do
          fetch.call
        end
      end

      expect(invoice.created_at.utc.to_s).to eq('2023-03-27 12:22:24 UTC')

      expect(invoice.state).to eq('settled')

      expect(invoice.secret.hash).to eq(secret_hash)
      expect(invoice.secret.preimage.size).to eq(64)
      expect(invoice.amount.millisatoshis).to eq(1000)

      expect(invoice.code).to eq('lnbcrt10n1pjzrz5qpp52v9dct3xju8dq2e58r5tydnqaa58d874q6e2zvv2qzpcexttxxysdq2gdhkven9v5cqzpgxqyz5vqsp54zks4d32d6vq7rtzunaafmmyjre9erlkxmcuwe94sz6xme70h5ks9qyyssqp2f6c4434q8ehaxz9lplgpey6zrz292zxqdldlz9awdhvrmtzwhy739xcwq76qprvlkkdc84yupeh8lfhck8c44yjpdjnjddq7672rgp36mffs')
    end
  end

  describe '.find_by_code' do
    context 'your invoice' do
      let(:code) do
        'lnbcrt10n1pjzrz5qpp52v9dct3xju8dq2e58r5tydnqaa58d874q6e2zvv2qzpcexttxxysdq2gdhkven9v5cqzpgxqyz5vqsp54zks4d32d6vq7rtzunaafmmyjre9erlkxmcuwe94sz6xme70h5ks9qyyssqp2f6c4434q8ehaxz9lplgpey6zrz292zxqdldlz9awdhvrmtzwhy739xcwq76qprvlkkdc84yupeh8lfhck8c44yjpdjnjddq7672rgp36mffs'
      end

      it 'finds' do
        invoice = described_class.find_by_code(code) do |fetch|
          VCR.tape.replay("Controller::Lightning::Invoice.find_by_code/#{code}") do
            fetch.call
          end
        end

        expect(invoice.created_at.utc.to_s).to eq('2023-03-27 12:22:24 UTC')

        expect(invoice.state).to eq('settled')

        expect(invoice.secret.hash).to eq('530adc2e26970ed02b3438e8b23660ef68769fd506b2a1318a00838c996b3189')
        expect(invoice.secret.preimage.size).to eq(64)
        expect(invoice.amount.millisatoshis).to eq(1000)

        expect(invoice.code).to eq(code)
      end
    end

    context 'not your invoice' do
      let(:code) do
        'lnbcrt10n1pjzj5dgpp5rdx6ay07lxf270t4qcfn6hexk54s6h64g42evmpvz68dtxet93aqdq2gdhkven9v5cqzpgxqyz5vqsp5hsxfc3k09yaldwalyfluy2d7599t9exv2lx2wfp0r2ur8sltz96q9qyyssqjv42wywr7ffvyj4kc40y649hvnzkj5mhmmndyezlqsq7x63akyq3dpp43xt76ggqrxctx46g0z6l24n805lcp55h893lwqm5felch0cpve5p0c'
      end

      it 'raises error' do
        expect do
          described_class.find_by_code(code) do |fetch|
            VCR.tape.replay("Controller::Lightning::Invoice.find_by_code/#{code}") do
              fetch.call
            end
          end
        end.to raise_error(
          NoInvoiceFoundError, "Invoice not found. Try using Invoice.decode if you don't own the invoice."
        )

        begin
          described_class.find_by_code(code) do |fetch|
            VCR.tape.replay("Controller::Lightning::Invoice.find_by_code/#{code}") do
              fetch.call
            end
          end
        rescue StandardError => e
          expect(e.class).to eq(NoInvoiceFoundError)
          expect(e.message).to eq("Invoice not found. Try using Invoice.decode if you don't own the invoice.")
          expect(e.grpc.class).to eq(GRPC::NotFound)
          expect(e.grpc.message).to match(/5:unable to locate invoice/)
        end
      end
    end
  end
end
