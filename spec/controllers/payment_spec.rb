# frozen_string_literal: true

require_relative '../../controllers/payment'

RSpec.describe Lighstorm::Controllers::Payment do
  describe '.find_by_secret_hash' do
    let(:secret_hash) { '3dadfa4f573b96e2b80a530fa6b5923869f9b22666d29cb7be79ef4be7ed028f' }

    it 'finds' do
      payment = described_class.find_by_secret_hash(secret_hash) do |fetch|
        VCR.tape.replay("Controllers::Payment.find_by_secret_hash/#{secret_hash}") do
          fetch.call
        end
      end

      expect(payment.secret.hash).to eq(secret_hash)
      expect(payment.secret.preimage.size).to eq(64)
      expect(payment.at.utc.to_s).to eq('2023-03-12 16:01:54 UTC')
      expect(payment.state).to eq('succeeded')
      expect(payment.amount.millisatoshis).to eq(49_000)
      expect(payment.fee.millisatoshis).to eq(0)
      expect(payment.invoice.code).to eq('lnbc490n1pjqma6vpp58kkl5n6h8wtw9wq22v86ddvj8p5lnv3xvmffeda708h5heldq28sdqyv93qcqzysxqr23ssp57jq9y6t4fsplxz6lgr3ryqtnf7y4xjc6hr90nasg44y23cc5xkgq9qyyssqfw6p66h7cdy93zh8fs4xd9s4a3fyy6pwj6t3t9t8d36w49vyrpzqdxrc9kwq9uqzg2eluaxet75px70dsltm0cg9qye967f09stcefsq92nuxh')
      expect(payment.invoice.description.memo).to eq('ab')
      expect(payment.invoice.amount.millisatoshis).to eq(49_000)
      expect(payment.invoice.state).to be_nil
    end
  end

  describe '.find_by_invoice_code' do
    let(:invoice_code) do
      'lnbc490n1pjqma6vpp58kkl5n6h8wtw9wq22v86ddvj8p5lnv3xvmffeda708h5heldq28sdqyv93qcqzysxqr23ssp57jq9y6t4fsplxz6lgr3ryqtnf7y4xjc6hr90nasg44y23cc5xkgq9qyyssqfw6p66h7cdy93zh8fs4xd9s4a3fyy6pwj6t3t9t8d36w49vyrpzqdxrc9kwq9uqzg2eluaxet75px70dsltm0cg9qye967f09stcefsq92nuxh'
    end

    it 'finds' do
      payment = described_class.find_by_invoice_code(invoice_code) do |fetch|
        VCR.tape.replay("Controllers::Payment.find_by_invoice_code/#{invoice_code}") do
          fetch.call
        end
      end

      expect(payment.secret.hash).to eq('3dadfa4f573b96e2b80a530fa6b5923869f9b22666d29cb7be79ef4be7ed028f')
      expect(payment.secret.preimage.size).to eq(64)
      expect(payment.at.utc.to_s).to eq('2023-03-12 16:01:54 UTC')
      expect(payment.state).to eq('succeeded')
      expect(payment.amount.millisatoshis).to eq(49_000)
      expect(payment.fee.millisatoshis).to eq(0)
      expect(payment.invoice.code).to eq('lnbc490n1pjqma6vpp58kkl5n6h8wtw9wq22v86ddvj8p5lnv3xvmffeda708h5heldq28sdqyv93qcqzysxqr23ssp57jq9y6t4fsplxz6lgr3ryqtnf7y4xjc6hr90nasg44y23cc5xkgq9qyyssqfw6p66h7cdy93zh8fs4xd9s4a3fyy6pwj6t3t9t8d36w49vyrpzqdxrc9kwq9uqzg2eluaxet75px70dsltm0cg9qye967f09stcefsq92nuxh')
      expect(payment.invoice.description.memo).to eq('ab')
      expect(payment.invoice.amount.millisatoshis).to eq(49_000)
      expect(payment.invoice.state).to be_nil
    end
  end
end
