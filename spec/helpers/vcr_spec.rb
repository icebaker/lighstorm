# frozen_string_literal: true

RSpec.describe VCR do
  describe 'build_path_for' do
    context 'too long' do
      let(:key) do
        'lightning.decode_pay_req/lnbc10n1p374jnvpp5qrdyr668cmh7ftnmv299nfxp4sle44dam9538r9agvyqggez9gusdqs2d68ycthvfjhyunecqzpgxqyz5vqsp5492cchna2qnqlf26azlljwatuxqcck7epagtx55lvgk9uw7gn4aq9qyyssqt5xs2rhg7z4x7pj2crazw5yfesugwzf03eylvsjgumfwvufp3vzq0lk98t5lm7np9x9465p7el07q07sl8nyyxnlc767mlanr8nvuzqpp3d65y'
      end
      let(:params) { {} }

      it 'builds' do
        expect(described_class.build_path_for(key, params)).to eq(
          'spec/data/tapes/lightning/decode_pay_req/lnbc10n1p374jnvpp5qrdyr668cmh7ftnmv299nfxp4sle44dam9538r9agvyqgge/40ad699496091dd7871a4ac435a2506330f0dca8379d2743b773150679aeb6b3.bin'
        )
      end
    end

    context 'common' do
      let(:key) { 'lightning.list_invoices.first/memo/settled' }
      let(:params) { { limit: 5 } }

      it 'builds' do
        expect(described_class.build_path_for(key, params)).to eq(
          'spec/data/tapes/lightning/list_invoices/first/memo/settled/limit/5.bin'
        )
      end
    end

    context 'common' do
      let(:key) { 'lightning.lookup_invoice' }
      let(:params) { { fetch: { lookup_invoice: false } } }

      it 'builds' do
        expect(described_class.build_path_for(key, params)).to eq(
          'spec/data/tapes/lightning/lookup_invoice/fetch/lookup_invoice/false.bin'
        )
      end
    end
  end
end
