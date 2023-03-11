# frozen_string_literal: true

require 'json'

require_relative '../../../../models/edges/channel'

RSpec.describe Lighstorm::Models::Channel do
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
    let(:dump) { symbolize_keys(JSON.parse(TestData.read("spec/data/gossip/channel/#{hash}/dump.json"))) }
    let(:gossip) { JSON.parse(TestData.read("spec/data/gossip/channel/#{hash}/gossip.json")) }

    context '29f0873593ae' do
      let(:hash) { '29f0873593ae' }

      it 'provides data portability' do
        channel = described_class.adapt(dump: dump)
        diff = channel.apply!(gossip: gossip)

        expect(diff).to eq(
          [{ path: [:partners, 1, :policy, :fee, :rate, :parts_per_million], from: 100, to: 150 },
           { path: [:partners, 1, :policy, :htlc, :minimum, :millisatoshis], from: 1000, to: 1200 },
           { path: [:partners, 1, :policy, :htlc, :maximum, :millisatoshis], from: 990_000_000,
             to: 920_000_000 },
           { path: [:partners, 1, :policy, :htlc, :blocks, :delta, :minimum], from: 40, to: 20 }]
        )
      end
    end

    context '367d90b62389' do
      let(:hash) { '367d90b62389' }

      it 'provides data portability' do
        channel = described_class.adapt(gossip: gossip)

        expect(channel.to_h).to eq(
          { _key: 'd727f0e4ecfd1a468a554a6f329e7c568a76999cf2a55d3cae231ec716537ed4',
            id: '766802707818938369',
            partners: [{ state: nil,
                         node: { _key: nil,
                                 public_key: '03d5099461761b1b4d3f3d2edfe9c929c71ad384ac18abe58a7188890964c8390a' },
                         policy: { fee: { rate: { parts_per_million: 150 } },
                                   htlc: { minimum: { millisatoshis: 1200 }, maximum: { millisatoshis: 920_000_000 },
                                           blocks: { delta: { minimum: 20 } } } } },
                       { state: nil,
                         node: { _key: nil,
                                 public_key: '02170ffa14bc0486252ad0213e698570cb5492955f6f6cd5ab97145a94e11ae696' } }] }
        )
      end
    end

    context '6506965fedda' do
      let(:hash) { '6506965fedda' }

      it 'provides data portability' do
        channel = described_class.adapt(dump: dump)
        diff = channel.apply!(gossip: gossip)

        expect(diff).to eq(
          [{ path: [:partners, 0, :policy, :fee, :base, :millisatoshis], from: nil, to: 2_147_483_647 },
           { path: [:partners, 0, :policy, :fee, :rate, :parts_per_million], from: nil, to: 2_147_483_647 },
           { path: [:partners, 0, :policy, :htlc, :minimum, :millisatoshis], from: nil, to: 1 },
           { path: [:partners, 0, :policy, :htlc, :maximum, :millisatoshis], from: nil, to: 15_093_000_000 },
           { path: [:partners, 0, :policy, :htlc, :blocks, :delta, :minimum], from: nil, to: 72 },
           { path: [:partners, 0, :state], from: nil, to: 'inactive' }]
        )
      end
    end

    context '8bb2503d3072' do
      let(:hash) { '8bb2503d3072' }

      it 'provides data portability' do
        channel = described_class.adapt(dump: dump)
        diff = channel.apply!(gossip: gossip)

        expect(diff).to eq(
          [{ path: [:partners, 1, :policy, :fee, :rate, :parts_per_million], from: 100, to: 150 },
           { path: [:partners, 1, :policy, :htlc, :minimum, :millisatoshis], from: 1000, to: 1200 },
           { path: [:partners, 1, :policy, :htlc, :maximum, :millisatoshis], from: 990_000_000,
             to: 920_000_000 },
           { path: [:partners, 1, :policy, :htlc, :blocks, :delta, :minimum], from: 40, to: 20 }]
        )
      end
    end

    context 'f328a264e336' do
      let(:hash) { 'f328a264e336' }

      it 'provides data portability' do
        channel = described_class.adapt(dump: dump)
        diff = channel.apply!(gossip: gossip)

        expect(diff).to eq(
          [{ path: [:partners, 0, :policy, :htlc, :minimum, :millisatoshis], from: nil, to: 1000 },
           { path: [:partners, 0, :policy, :htlc, :maximum, :millisatoshis], from: nil, to: 396_000_000 },
           { path: [:partners, 0, :policy, :htlc, :blocks, :delta, :minimum], from: nil, to: 144 }]
        )
      end
    end
  end
end
