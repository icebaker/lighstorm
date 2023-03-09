# frozen_string_literal: true

require 'json'

# Circular dependency issue:
# https://stackoverflow.com/questions/8057625/ruby-how-to-require-correctly-to-avoid-circular-dependencies
require_relative '../../../../models/edges/channel/hop'
require_relative '../../../../models/edges/channel'
require_relative '../../../../controllers/channel/find_by_id'
require_relative '../../../../ports/dsl/lighstorm/errors'

RSpec.describe Lighstorm::Models::Channel do
  describe '.apply!' do
    let(:channel) do
      data = Lighstorm::Controllers::Channel::FindById.data(channel_id) do |fetch|
        VCR.tape.replay("Controllers::Channel.find_by_id/#{channel_id}") { fetch.call }
      end

      described_class.new(data)
    end

    context 'complete without changes A' do
      let(:channel_id) { 837_471_618_647_916_545 }

      it 'applies the gossip' do
        previous_dump = channel.dump

        gossip = JSON.parse(TestData.read('spec/data/gossip/channel/sample-a.json'))

        diff = channel.apply!(gossip: gossip)

        expect(diff).to eq([])

        expect(channel.dump).to eq(previous_dump)
      end
    end

    context 'complete with changes error B' do
      let(:channel_id) { 837_471_618_647_916_545 }

      it 'applies the gossip' do
        previous_dump = channel.dump

        gossip = JSON.parse(TestData.read('spec/data/gossip/channel/sample-b.json'))

        expect { channel.apply!(gossip: gossip) }.to raise_error(
          IncoherentGossipError, "Gossip doesn't belong to this Channel"
        )
      end
    end

    context 'complete with changes B' do
      let(:channel_id) { 798_835_879_549_927_425 }

      it 'applies the gossip' do
        previous_to_h = channel.to_h
        previous_dump = channel.dump

        gossip = JSON.parse(TestData.read('spec/data/gossip/channel/sample-b.json'))

        expect(channel.partners[0].policy.fee.base.millisatoshis).not_to eq(150)

        diff = channel.apply!(gossip: gossip)

        expect(channel.partners[0].policy.fee.base.millisatoshis).to eq(150)

        expect(diff).to eq(
          [{ from: 100, path: [:partners, 0, :policy, :fee, :base, :millisatoshis], to: 150 }]
        )

        expect(channel.to_h).not_to eq(previous_to_h)
        expect(channel.dump).not_to eq(previous_dump)
      end
    end

    context 'complete with changes C' do
      let(:channel_id) { 838_301_749_944_647_681 }

      it 'applies the gossip' do
        previous_to_h = channel.to_h
        previous_dump = channel.dump

        gossip = JSON.parse(TestData.read('spec/data/gossip/channel/sample-c.json'))

        expect(channel.partners[0].state).not_to eq('inactive')

        diff = channel.apply!(gossip: gossip)

        expect(channel.partners[0].state).to eq('inactive')

        expect(diff).to eq(
          [{ from: 'active', path: [:partners, 0, :state], to: 'inactive' }]
        )

        expect(channel.to_h).not_to eq(previous_to_h)
        expect(channel.dump).not_to eq(previous_dump)
      end
    end

    context 'all fields D' do
      let(:channel_id) { 837_471_618_647_916_545 }

      it 'applies the gossip' do
        previous_to_h = channel.to_h
        previous_dump = channel.dump

        gossip = JSON.parse(TestData.read('spec/data/gossip/channel/sample-d.json'))

        expect(previous_to_h).to eq(
          { _key: '36c34f134dd6b41c4bb9c8a84e90e6903d9fff663af6cfe2ea68acdca5660f46',
            id: '837471618647916545',
            accounting: { capacity: { millisatoshis: 5_000_000_000 } },
            partners: [
              { state: 'active',
                node: {
                  _key: 'de2939d174ddd01e051a5b05e3e2e40479d0dfd16ee5295c0b4985890a603ffc',
                  public_key: '0201af659a3986832bb5bf2493c537cee9f7d62a7bff5d0a68176c1d60df931cf7',
                  alias: 'SatoshiIsProudOfUs',
                  color: '#fa770f',
                  platform: { blockchain: 'bitcoin', network: 'mainnet' }
                },
                policy: {
                  fee: {
                    base: { millisatoshis: 0 },
                    rate: { parts_per_million: 700 }
                  },
                  htlc: {
                    minimum: { millisatoshis: 1000 },
                    maximum: { millisatoshis: 4_950_000_000 },
                    blocks: { delta: { minimum: 40 } }
                  }
                } },
              { state: 'active',
                node: {
                  _key: '713519e5aca513a070deedc0520be905e0fc3e36f555c33f977b6c369b7d76fb',
                  public_key: '037659a0ac8eb3b8d0a720114efc861d3a940382dcfa1403746b4f8f6b2e8810ba',
                  alias: 'ln.nicehash.com [Nicehash]',
                  color: '#cf1b99',
                  platform: { blockchain: 'bitcoin', network: 'mainnet' }
                },
                policy: {
                  fee: {
                    base: { millisatoshis: 1000 },
                    rate: { parts_per_million: 300 }
                  },
                  htlc: {
                    minimum: { millisatoshis: 1000 },
                    maximum: { millisatoshis: 4_950_000_000 },
                    blocks: { delta: { minimum: 144 } }
                  }
                } }
            ] }
        )

        expect(previous_dump).to eq(
          { _source: :get_chan_info,
            _key: '36c34f134dd6b41c4bb9c8a84e90e6903d9fff663af6cfe2ea68acdca5660f46',
            id: '837471618647916545',
            accounting: { capacity: { millisatoshis: 5_000_000_000 } },
            partners: [
              { _source: :get_chan_info,
                node: {
                  _source: :get_node_info,
                  _key: 'de2939d174ddd01e051a5b05e3e2e40479d0dfd16ee5295c0b4985890a603ffc',
                  public_key: '0201af659a3986832bb5bf2493c537cee9f7d62a7bff5d0a68176c1d60df931cf7',
                  alias: 'SatoshiIsProudOfUs',
                  color: '#fa770f',
                  platform: { blockchain: 'bitcoin', network: 'mainnet' },
                  myself: false
                },
                state: 'active',
                policy: {
                  fee: { base: { millisatoshis: 0 }, rate: { parts_per_million: 700 } },
                  htlc: {
                    minimum: { millisatoshis: 1000 },
                    maximum: { millisatoshis: 4_950_000_000 },
                    blocks: { delta: { minimum: 40 } }
                  }
                } },
              { _source: :get_chan_info,
                node: {
                  _source: :get_node_info,
                  _key: '713519e5aca513a070deedc0520be905e0fc3e36f555c33f977b6c369b7d76fb',
                  public_key: '037659a0ac8eb3b8d0a720114efc861d3a940382dcfa1403746b4f8f6b2e8810ba',
                  alias: 'ln.nicehash.com [Nicehash]',
                  color: '#cf1b99',
                  platform: { blockchain: 'bitcoin', network: 'mainnet' },
                  myself: false
                },
                state: 'active',
                policy: {
                  fee: { base: { millisatoshis: 1000 },
                         rate: { parts_per_million: 300 } },
                  htlc: {
                    minimum: { millisatoshis: 1000 },
                    maximum: { millisatoshis: 4_950_000_000 },
                    blocks: { delta: { minimum: 144 } }
                  }
                } }
            ],
            known: true,
            mine: false,
            exposure: 'public' }
        )

        expect(channel.accounting.capacity.millisatoshis).not_to eq(6_000_000_000)

        expect(channel.partners[1].state).not_to eq('inactive')

        expect(channel.partners[1].policy.fee.base.millisatoshis).not_to eq(1700)
        expect(channel.partners[1].policy.fee.rate.parts_per_million).not_to eq(800)

        expect(channel.partners[1].policy.htlc.maximum.millisatoshis).not_to eq(5_950_000_000)
        expect(channel.partners[1].policy.htlc.minimum.millisatoshis).not_to eq(1400)
        expect(channel.partners[1].policy.htlc.blocks.delta.minimum).not_to eq(200)

        diff = channel.apply!(gossip: gossip)

        expect(channel.accounting.capacity.millisatoshis).to eq(6_000_000_000)

        expect(channel.partners[1].state).to eq('inactive')

        expect(channel.partners[1].policy.fee.base.millisatoshis).to eq(1700)
        expect(channel.partners[1].policy.fee.rate.parts_per_million).to eq(800)

        expect(channel.partners[1].policy.htlc.maximum.millisatoshis).to eq(5_950_000_000)
        expect(channel.partners[1].policy.htlc.minimum.millisatoshis).to eq(1400)
        expect(channel.partners[1].policy.htlc.blocks.delta.minimum).to eq(200)

        expect(diff).to eq(
          [{
            path: %i[accounting capacity millisatoshis],
            from: 5_000_000_000, to: 6_000_000_000
          },
           {
             path: [:partners, 1, :policy, :fee, :base, :millisatoshis],
             from: 1000, to: 1700
           },
           {
             path: [:partners, 1, :policy, :fee, :rate, :parts_per_million],
             from: 300, to: 800
           },
           {
             path: [:partners, 1, :policy, :htlc, :minimum, :millisatoshis],
             from: 1000, to: 1400
           },
           { path: [:partners, 1, :policy, :htlc, :maximum, :millisatoshis],
             from: 4_950_000_000, to: 5_950_000_000 },
           {
             path: [:partners, 1, :policy, :htlc, :blocks, :delta, :minimum],
             from: 144, to: 200
           },
           {
             path: [:partners, 1, :state],
             from: 'active', to: 'inactive'
           }]
        )

        expect(channel.to_h).not_to eq(previous_to_h)
        expect(channel.dump).not_to eq(previous_dump)

        expect(channel.to_h).to eq(
          { _key: '36c34f134dd6b41c4bb9c8a84e90e6903d9fff663af6cfe2ea68acdca5660f46',
            id: '837471618647916545',
            accounting: { capacity: { millisatoshis: 6_000_000_000 } },
            partners: [{ state: 'active',
                         node: { _key: 'de2939d174ddd01e051a5b05e3e2e40479d0dfd16ee5295c0b4985890a603ffc',
                                 public_key: '0201af659a3986832bb5bf2493c537cee9f7d62a7bff5d0a68176c1d60df931cf7',
                                 alias: 'SatoshiIsProudOfUs',
                                 color: '#fa770f',
                                 platform: { blockchain: 'bitcoin', network: 'mainnet' } },
                         policy: { fee: { base: { millisatoshis: 0 }, rate: { parts_per_million: 700 } },
                                   htlc: { minimum: { millisatoshis: 1000 }, maximum: { millisatoshis: 4_950_000_000 },
                                           blocks: { delta: { minimum: 40 } } } } },
                       { state: 'inactive',
                         node: { _key: '713519e5aca513a070deedc0520be905e0fc3e36f555c33f977b6c369b7d76fb',
                                 public_key: '037659a0ac8eb3b8d0a720114efc861d3a940382dcfa1403746b4f8f6b2e8810ba',
                                 alias: 'ln.nicehash.com [Nicehash]',
                                 color: '#cf1b99',
                                 platform: { blockchain: 'bitcoin', network: 'mainnet' } },
                         policy: { fee: { base: { millisatoshis: 1700 }, rate: { parts_per_million: 800 } },
                                   htlc: { minimum: { millisatoshis: 1400 }, maximum: { millisatoshis: 5_950_000_000 },
                                           blocks: { delta: { minimum: 200 } } } } }] }
        )

        expect(channel.dump).to eq(
          { _source: :get_chan_info,
            _key: '36c34f134dd6b41c4bb9c8a84e90e6903d9fff663af6cfe2ea68acdca5660f46',
            id: '837471618647916545',
            accounting: { capacity: { millisatoshis: 6_000_000_000 } },
            partners: [{ _source: :get_chan_info,
                         node: { _source: :get_node_info,
                                 _key: 'de2939d174ddd01e051a5b05e3e2e40479d0dfd16ee5295c0b4985890a603ffc',
                                 public_key: '0201af659a3986832bb5bf2493c537cee9f7d62a7bff5d0a68176c1d60df931cf7',
                                 alias: 'SatoshiIsProudOfUs',
                                 color: '#fa770f',
                                 platform: { blockchain: 'bitcoin', network: 'mainnet' },
                                 myself: false },
                         state: 'active',
                         policy: { fee: { base: { millisatoshis: 0 }, rate: { parts_per_million: 700 } },
                                   htlc: { minimum: { millisatoshis: 1000 }, maximum: { millisatoshis: 4_950_000_000 },
                                           blocks: { delta: { minimum: 40 } } } } },
                       { _source: :get_chan_info,
                         node: { _source: :get_node_info,
                                 _key: '713519e5aca513a070deedc0520be905e0fc3e36f555c33f977b6c369b7d76fb',
                                 public_key: '037659a0ac8eb3b8d0a720114efc861d3a940382dcfa1403746b4f8f6b2e8810ba',
                                 alias: 'ln.nicehash.com [Nicehash]',
                                 color: '#cf1b99',
                                 platform: { blockchain: 'bitcoin', network: 'mainnet' },
                                 myself: false },
                         state: 'inactive',
                         policy: { fee: { base: { millisatoshis: 1700 }, rate: { parts_per_million: 800 } },
                                   htlc: { minimum: { millisatoshis: 1400 }, maximum: { millisatoshis: 5_950_000_000 },
                                           blocks: { delta: { minimum: 200 } } } } }],
            known: true,
            mine: false,
            exposure: 'public' }
        )
      end
    end

    context 'from empty' do
      it 'applies the gossip' do
        gossip = JSON.parse(TestData.read('spec/data/gossip/channel/sample-d.json'))

        channel = described_class.adapt(gossip: gossip)

        expect(channel.to_h).to eq(
          { _key: '36c34f134dd6b41c4bb9c8a84e90e6903d9fff663af6cfe2ea68acdca5660f46',
            id: '837471618647916545',
            partners: [
              { state: 'inactive',
                node: { _key: nil,
                        public_key: '037659a0ac8eb3b8d0a720114efc861d3a940382dcfa1403746b4f8f6b2e8810ba' },
                policy: {
                  fee: {
                    base: { millisatoshis: 1700 },
                    rate: { parts_per_million: 800 }
                  },
                  htlc: {
                    minimum: { millisatoshis: 1400 },
                    maximum: { millisatoshis: 5_950_000_000 },
                    blocks: { delta: { minimum: 200 } }
                  }
                } },
              { state: nil,
                node: { _key: nil,
                        public_key: '0201af659a3986832bb5bf2493c537cee9f7d62a7bff5d0a68176c1d60df931cf7' } }
            ] }
        )

        expect(channel.dump).to eq(
          { _source: :subscribe_channel_graph,
            _key: '36c34f134dd6b41c4bb9c8a84e90e6903d9fff663af6cfe2ea68acdca5660f46',
            id: '837471618647916545',
            accounting: {
              capacity: { millisatoshis: 6_000_000_000 }
            },
            partners: [
              { _source: :subscribe_channel_graph,
                node: { public_key: '037659a0ac8eb3b8d0a720114efc861d3a940382dcfa1403746b4f8f6b2e8810ba' },
                policy: {
                  _source: :subscribe_channel_graph,
                  fee: {
                    base: { millisatoshis: 1700 },
                    rate: { parts_per_million: 800 }
                  },
                  htlc: {
                    minimum: { millisatoshis: 1400 },
                    maximum: { millisatoshis: 5_950_000_000 },
                    blocks: { delta: { minimum: 200 } }
                  }
                },
                state: 'inactive' },
              { node: { public_key: '0201af659a3986832bb5bf2493c537cee9f7d62a7bff5d0a68176c1d60df931cf7' } }
            ] }
        )

        expect { channel.apply!(gossip: gossip) }.not_to raise_error
      end
    end
  end
end
