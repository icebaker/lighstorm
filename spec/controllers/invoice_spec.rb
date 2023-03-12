# frozen_string_literal: true

require_relative '../../controllers/invoice'

RSpec.describe Lighstorm::Controllers::Invoice do
  describe '.find_by_secret_hash' do
    let(:secret_hash) { 'cd1833b549a3f2bd115b433eb21279c185c9a94457062d9b9763b0129fdee567' }

    it 'finds' do
      invoice = described_class.find_by_secret_hash(secret_hash) do |fetch|
        VCR.tape.replay("Controllers::Invoice.find_by_secret_hash/#{secret_hash}") do
          fetch.call
        end
      end

      expect(invoice.created_at.utc.to_s).to eq('2023-03-12 18:24:48 UTC')

      expect(invoice.state).to eq('settled')

      expect(invoice.secret.hash).to eq(secret_hash)
      expect(invoice.secret.preimage.size).to eq(64)
      expect(invoice.amount.millisatoshis).to eq(1000)

      expect(invoice.code).to eq('lnbc10n1pjqux8spp5e5vr8d2f50et6y2mgvltyynecxzun22y2urzmxuhvwcp9877u4nsdqcxysyxatsyphkvgzrdanxvet9cqzpgxqyz5vqsp5ku00sl5p5r76eu9aw6n7mzny9d94r03hpr69r9uvh9yc074pepds9qyyssq0q79336f9qpdfztfflmkfyzweucsphw008mhh2nmtz2m27vugpsnjay5q5p5p5d0dl2gvakzplg757xw8efu4734lpgr88z2y9t3rjqqgfn9yd')
    end
  end

  describe '.find_by_code' do
    context 'your invoice' do
      let(:code) do
        'lnbc10n1pjqux8spp5e5vr8d2f50et6y2mgvltyynecxzun22y2urzmxuhvwcp9877u4nsdqcxysyxatsyphkvgzrdanxvet9cqzpgxqyz5vqsp5ku00sl5p5r76eu9aw6n7mzny9d94r03hpr69r9uvh9yc074pepds9qyyssq0q79336f9qpdfztfflmkfyzweucsphw008mhh2nmtz2m27vugpsnjay5q5p5p5d0dl2gvakzplg757xw8efu4734lpgr88z2y9t3rjqqgfn9yd'
      end

      it 'finds' do
        invoice = described_class.find_by_code(code) do |fetch|
          VCR.tape.replay("Controllers::Invoice.find_by_code/#{code}") do
            fetch.call
          end
        end

        expect(invoice.created_at.utc.to_s).to eq('2023-03-12 18:24:48 UTC')

        expect(invoice.state).to eq('settled')

        expect(invoice.secret.hash).to eq('cd1833b549a3f2bd115b433eb21279c185c9a94457062d9b9763b0129fdee567')
        expect(invoice.secret.preimage.size).to eq(64)
        expect(invoice.amount.millisatoshis).to eq(1000)

        expect(invoice.code).to eq(code)
      end
    end

    context 'not your invoice' do
      let(:code) do
        'lnbc490n1pjqma6vpp58kkl5n6h8wtw9wq22v86ddvj8p5lnv3xvmffeda708h5heldq28sdqyv93qcqzysxqr23ssp57jq9y6t4fsplxz6lgr3ryqtnf7y4xjc6hr90nasg44y23cc5xkgq9qyyssqfw6p66h7cdy93zh8fs4xd9s4a3fyy6pwj6t3t9t8d36w49vyrpzqdxrc9kwq9uqzg2eluaxet75px70dsltm0cg9qye967f09stcefsq92nuxh'
      end

      it 'raises error' do
        expect do
          described_class.find_by_code(code) do |fetch|
            VCR.tape.replay("Controllers::Invoice.find_by_code/#{code}") do
              fetch.call
            end
          end
        end.to raise_error(
          NoInvoiceFoundError, "Invoice not found. Try using Invoice.decode if you don't own the invoice."
        )

        begin
          described_class.find_by_code(code) do |fetch|
            VCR.tape.replay("Controllers::Invoice.find_by_code/#{code}") do
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
