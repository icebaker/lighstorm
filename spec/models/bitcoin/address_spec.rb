# frozen_string_literal: true

require 'json'

require_relative '../../../models/bitcoin/address'

RSpec.describe Lighstorm::Model::Bitcoin::Address do
  describe 'new' do
    context 'mainnet' do
      context 'taproot' do
        let(:code) { 'bc1pd5jgrk4k0qmrl3ddr0qrap0nrafrdydpsznq9v3a5ny33fz6tklsqut72a' }

        it 'infers' do
          address = described_class.new({ code: code }, nil)
          expect(address.code).to eq(code)
          expect(address.specification.format).to eq('taproot')
          expect(address.specification.bip).to eq(341)
          expect(address.specification.code).to eq('P2TR')
          expect(address.specification.to_h).to eq(
            { format: 'taproot', code: 'P2TR', bip: 341 }
          )

          expect(address.to_h).to eq(
            { code: 'bc1pd5jgrk4k0qmrl3ddr0qrap0nrafrdydpsznq9v3a5ny33fz6tklsqut72a',
              specification: { bip: 341, code: 'P2TR', format: 'taproot' } }
          )
        end
      end

      context 'segwit' do
        let(:code) { 'bc1q99rjmzg9wgt80p2jt9540e7hyv4n2z0t5037rq' }

        it 'infers' do
          address = described_class.new({ code: code }, nil)
          expect(address.code).to eq(code)
          expect(address.specification.format).to eq('segwit')
          expect(address.specification.bip).to eq(173)
          expect(address.specification.code).to eq('P2WPKH')
          expect(address.specification.to_h).to eq(
            { format: 'segwit', code: 'P2WPKH', bip: 173 }
          )

          expect(address.to_h).to eq(
            { code: 'bc1q99rjmzg9wgt80p2jt9540e7hyv4n2z0t5037rq',
              specification: { bip: 173, code: 'P2WPKH', format: 'segwit' } }
          )
        end
      end

      context 'script' do
        let(:code) { '3DfDoqRCYznGZtPLbtJSvk2VoqPk1if9Eq' }

        it 'infers' do
          address = described_class.new({ code: code }, nil)
          expect(address.code).to eq(code)
          expect(address.specification.format).to eq('script')
          expect(address.specification.bip).to eq(16)
          expect(address.specification.code).to eq('P2SH')
          expect(address.specification.to_h).to eq(
            { format: 'script', code: 'P2SH', bip: 16 }
          )

          expect(address.to_h).to eq(
            { code: '3DfDoqRCYznGZtPLbtJSvk2VoqPk1if9Eq',
              specification: { bip: 16, code: 'P2SH', format: 'script' } }
          )
        end
      end

      context 'legacy' do
        let(:code) { '1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2' }

        it 'infers' do
          address = described_class.new({ code: code }, nil)
          expect(address.code).to eq(code)
          expect(address.specification.format).to eq('legacy')
          expect(address.specification.bip).to be_nil
          expect(address.specification.code).to eq('P2PKH')
          expect(address.specification.to_h).to eq(
            { format: 'legacy', code: 'P2PKH', bip: nil }
          )

          expect(address.to_h).to eq(
            { code: '1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2',
              specification: { bip: nil, code: 'P2PKH', format: 'legacy' } }
          )
        end
      end

      context 'unknown' do
        let(:code) { 'lorem' }

        it 'infers' do
          address = described_class.new({ code: code }, nil)
          expect(address.code).to eq(code)
          expect(address.specification.format).to eq('unknown')
          expect(address.specification.bip).to be_nil
          expect(address.specification.code).to be_nil
          expect(address.specification.to_h).to eq(
            { format: 'unknown', code: nil, bip: nil }
          )

          expect(address.to_h).to eq(
            { code: 'lorem',
              specification: { bip: nil, code: nil, format: 'unknown' } }
          )
        end
      end
    end

    context 'regtest' do
      context 'taproot' do
        let(:code) { 'bcrt1pdsnzpdjmetxmpp5tw769x3htjpx3wvkeflnut7knwmxlkkwe3svsvgwfht' }

        it 'infers' do
          address = described_class.new({ code: code }, nil)
          expect(address.code).to eq(code)
          expect(address.specification.format).to eq('taproot')
          expect(address.specification.bip).to eq(341)
          expect(address.specification.code).to eq('P2TR')
          expect(address.specification.to_h).to eq(
            { format: 'taproot', code: 'P2TR', bip: 341 }
          )

          expect(address.to_h).to eq(
            { code: 'bcrt1pdsnzpdjmetxmpp5tw769x3htjpx3wvkeflnut7knwmxlkkwe3svsvgwfht',
              specification: { bip: 341, code: 'P2TR', format: 'taproot' } }
          )
        end
      end

      context 'segwit' do
        let(:code) { 'bcrt1qmzauakqp7wqae3gyf0ctqhza5qxjtheghrcjna' }

        it 'infers' do
          address = described_class.new({ code: code }, nil)
          expect(address.code).to eq(code)
          expect(address.specification.format).to eq('segwit')
          expect(address.specification.bip).to eq(173)
          expect(address.specification.code).to eq('P2WPKH')
          expect(address.specification.to_h).to eq(
            { format: 'segwit', code: 'P2WPKH', bip: 173 }
          )

          expect(address.to_h).to eq(
            { code: 'bcrt1qmzauakqp7wqae3gyf0ctqhza5qxjtheghrcjna',
              specification: { bip: 173, code: 'P2WPKH', format: 'segwit' } }
          )
        end
      end

      context 'script' do
        let(:code) { '2N3oviLwazRtd5SaTSEkaULKbGny5yAHnqs' }

        it 'infers' do
          address = described_class.new({ code: code }, nil)
          expect(address.code).to eq(code)
          expect(address.specification.format).to eq('script')
          expect(address.specification.bip).to eq(16)
          expect(address.specification.code).to eq('P2SH')
          expect(address.specification.to_h).to eq(
            { format: 'script', code: 'P2SH', bip: 16 }
          )

          expect(address.to_h).to eq(
            { code: '2N3oviLwazRtd5SaTSEkaULKbGny5yAHnqs',
              specification: { bip: 16, code: 'P2SH', format: 'script' } }
          )
        end
      end

      context 'legacy' do
        let(:code) { '1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2' }

        it 'infers' do
          address = described_class.new({ code: code }, nil)
          expect(address.code).to eq(code)
          expect(address.specification.format).to eq('legacy')
          expect(address.specification.bip).to be_nil
          expect(address.specification.code).to eq('P2PKH')
          expect(address.specification.to_h).to eq(
            { format: 'legacy', code: 'P2PKH', bip: nil }
          )

          expect(address.to_h).to eq(
            { code: '1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2',
              specification: { bip: nil, code: 'P2PKH', format: 'legacy' } }
          )
        end
      end

      context 'unknown' do
        let(:code) { 'lorem' }

        it 'infers' do
          address = described_class.new({ code: code }, nil)
          expect(address.code).to eq(code)
          expect(address.specification.format).to eq('unknown')
          expect(address.specification.bip).to be_nil
          expect(address.specification.code).to be_nil
          expect(address.specification.to_h).to eq(
            { format: 'unknown', code: nil, bip: nil }
          )

          expect(address.to_h).to eq(
            { code: 'lorem',
              specification: { bip: nil, code: nil, format: 'unknown' } }
          )
        end
      end
    end
  end
end
