# frozen_string_literal: true

require 'json'

require_relative '../../../../models/nodes/node'

RSpec.describe Lighstorm::Models::Node do
  context 'error' do
    it 'raises error' do
      expect { described_class.adapt }.to raise_error(
        ArgumentError, 'missing gossip: or dump:'
      )

      expect { described_class.adapt(gossip: {}, dump: {}) }.to raise_error(
        TooManyArgumentsError, 'you need to pass gossip: or dump:, not both'
      )
    end
  end

  describe '.apply!' do
    let(:dump) { symbolize_keys(JSON.parse(File.read("spec/data/gossip/node/#{hash}/dump.json"))) }
    let(:gossip) { JSON.parse(File.read("spec/data/gossip/node/#{hash}/gossip.json")) }

    context '4dec8c315434' do
      let(:hash) { '4dec8c315434' }

      it 'provides data portability' do
        node = described_class.adapt(dump: dump)
        diff = node.apply!(gossip: gossip)

        expect(diff).to eq(
          [{ path: [:alias], from: 'Gerdtrudroepke', to: 'GerdtrudroepkeA' },
           { path: [:color], from: '#ff5000', to: '#ff5002' }]
        )
      end
    end

    context 'e0f26f5929be' do
      let(:hash) { 'e0f26f5929be' }

      it 'provides data portability' do
        node = described_class.adapt(dump: dump)
        diff = node.apply!(gossip: gossip)

        expect(diff).to eq(
          [{ path: [:alias], from: 'Gerdtrudroepke', to: 'GerdtrudroepkeA' },
           { path: [:color], from: '#ff5000', to: '#ff5002' }]
        )
      end
    end

    context 'e957d7ca7573' do
      let(:hash) { 'e957d7ca7573' }

      it 'provides data portability' do
        node = described_class.adapt(dump: dump)
        diff = node.apply!(gossip: gossip)

        expect(diff).to eq(
          []
        )
      end
    end

    context 'ef0ca4752244' do
      let(:hash) { 'ef0ca4752244' }

      it 'provides data portability' do
        node = described_class.adapt(gossip: gossip)

        expect(node.to_h).to eq(
          { _key: '8b8b460416bc384260ca166233827f361a0c0da7b632c68a2720e08fbe3f528c',
            public_key: '023c047f51141b345db60fb4bf7a6a863ed9e010fa8eaba0d596322565a6b9a73b',
            alias: 'GerdtrudroepkeA',
            color: '#ff5002' }
        )
      end
    end
  end
end
