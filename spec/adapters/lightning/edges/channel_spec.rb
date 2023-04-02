# frozen_string_literal: true

require 'json'

require_relative '../../../../adapters/lightning/edges/channel'
require_relative '../../../../ports/grpc'

RSpec.describe Lighstorm::Adapter::Lightning::Channel do
  context 'list_channels' do
    it 'adapts' do
      raw = VCR.tape.replay('lightning.list_channels.channels.first') do
        Lighstorm::Ports::GRPC.lightning.list_channels.channels.first.to_h
      end

      Contract.expect(
        raw,
        '2c44dfe9ee5cba213084a3e83bad623c79ad9384200c52dba3d48a7f74611679'
      ) do |actual, expected|
        expect(actual.hash).to eq(expected.hash)
        expect(actual.contract).to eq(expected.contract)
      end

      at = Time.new(2023, 2, 14, 13, 21, 0)

      adapted = described_class.list_channels(raw, at)

      Contract.expect(
        adapted,
        'cb0d920a74f78177f3bd03253dae62f33157cf6c99c4fbcebc98ff9caa985cb9'
      ) do |actual, expected|
        expect(actual.hash).to eq(expected.hash)
        expect(actual.contract).to eq(expected.contract)
      end
    end
  end

  context 'get_chan_info' do
    context 'my channel' do
      it 'adapts' do
        channel_id = 118_747_255_865_345

        raw = VCR.tape.replay('lightning.get_chan_info', chan_id: channel_id) do
          Lighstorm::Ports::GRPC.lightning.get_chan_info(chan_id: channel_id).to_h
        end

        Contract.expect(
          raw,
          '6435cb37184004825e52beb929c7dd3def4ea690f9b5b17aedbefc3e6fbd21c7'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)
        end

        adapted = described_class.get_chan_info(raw)

        expect(adapted).to eq(
          { _source: :get_chan_info,
            _key: 'f0d6de06aca8e43418a4ba5c336b2cd757a38c0d28322e84907dad5f11696226',
            id: '118747255865345',
            accounting: { capacity: { millisatoshis: 250_000_000 } },
            partners: [{ _source: :get_chan_info,
                         node: { _source: :get_chan_info,
                                 _key: 'fbce6d195972b53499122086de9b05244cef69393d8cb5d7402c2c60df736c1f',
                                 public_key: '02dc08e2bf7d833afd7b8dc0f8f4afd7cd64e12eb4683c8e7be95fdc13269942d6' },
                         state: 'active',
                         policy: { fee: { base: { millisatoshis: 1000 }, rate: { parts_per_million: 1 } },
                                   htlc: { minimum: { millisatoshis: 1000 }, maximum: { millisatoshis: 247_500_000 },
                                           blocks: { delta: { minimum: 40 } } } } },
                       { _source: :get_chan_info,
                         node: { _source: :get_chan_info,
                                 _key: '290dccbd735b7163bc66bfb6c385240a28ad7f6a22123140f924f5d7c1ce0ec0',
                                 public_key: '030312fd8a77809402f2199a2b4e84b299f74060b715726303ed1e60ce611786d4' },
                         state: 'active',
                         policy: { fee: { base: { millisatoshis: 1000 }, rate: { parts_per_million: 1 } },
                                   htlc: { minimum: { millisatoshis: 1000 }, maximum: { millisatoshis: 247_500_000 },
                                           blocks: { delta: { minimum: 40 } } } } }] }
        )
      end
    end

    context 'other channel' do
      it 'adapts' do
        channel_id = 197_912_093_065_217

        raw = VCR.tape.replay('lightning.get_chan_info', chan_id: channel_id) do
          Lighstorm::Ports::GRPC.lightning.get_chan_info(chan_id: channel_id).to_h
        end

        Contract.expect(
          raw,
          '6435cb37184004825e52beb929c7dd3def4ea690f9b5b17aedbefc3e6fbd21c7'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)
        end

        adapted = described_class.get_chan_info(raw)

        expect(adapted).to eq(
          { _source: :get_chan_info,
            _key: '669c25d50862927bdcc1800f1c6a558c7166b7a54ad4374573632e07fb603af9',
            id: '197912093065217',
            accounting: { capacity: { millisatoshis: 250_000_000 } },
            partners: [{ _source: :get_chan_info,
                         node: { _source: :get_chan_info,
                                 _key: '290dccbd735b7163bc66bfb6c385240a28ad7f6a22123140f924f5d7c1ce0ec0',
                                 public_key: '030312fd8a77809402f2199a2b4e84b299f74060b715726303ed1e60ce611786d4' },
                         state: 'active',
                         policy: { fee: { base: { millisatoshis: 1000 }, rate: { parts_per_million: 1 } },
                                   htlc: { minimum: { millisatoshis: 1000 }, maximum: { millisatoshis: 247_500_000 },
                                           blocks: { delta: { minimum: 40 } } } } },
                       { _source: :get_chan_info,
                         node: { _source: :get_chan_info,
                                 _key: '790183426e81694c13758550dd4a9251ddc2dbeb1ea2b877ce3d808792df2dde',
                                 public_key: '03d70b5787c8be68bf63cd7b51d2074dfcc767dc975b7ac6cf1a17717ee12d8a44' },
                         state: 'active',
                         policy: { fee: { base: { millisatoshis: 1000 }, rate: { parts_per_million: 1 } },
                                   htlc: { minimum: { millisatoshis: 1000 }, maximum: { millisatoshis: 247_500_000 },
                                           blocks: { delta: { minimum: 40 } } } } }] }
        )
      end
    end
  end

  context 'describe_graph' do
    context 'first' do
      it 'adapts' do
        raw = VCR.tape.replay('lightning.describe_graph.edges.first') do
          Lighstorm::Ports::GRPC.lightning.describe_graph.edges.first.to_h
        end

        Contract.expect(
          raw,
          '6435cb37184004825e52beb929c7dd3def4ea690f9b5b17aedbefc3e6fbd21c7'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)
        end

        adapted = described_class.describe_graph(raw)

        expect(adapted).to eq(
          { _source: :describe_graph,
            _key: 'f0d6de06aca8e43418a4ba5c336b2cd757a38c0d28322e84907dad5f11696226',
            id: '118747255865345',
            exposure: 'public',
            accounting: { capacity: { millisatoshis: 250_000_000 } },
            partners: [{ _source: :describe_graph,
                         node: { _source: :describe_graph,
                                 _key: 'fbce6d195972b53499122086de9b05244cef69393d8cb5d7402c2c60df736c1f',
                                 public_key: '02dc08e2bf7d833afd7b8dc0f8f4afd7cd64e12eb4683c8e7be95fdc13269942d6' },
                         state: 'active',
                         policy: { fee: { base: { millisatoshis: 1000 }, rate: { parts_per_million: 1 } },
                                   htlc: { minimum: { millisatoshis: 1000 }, maximum: { millisatoshis: 247_500_000 },
                                           blocks: { delta: { minimum: 40 } } } } },
                       { _source: :describe_graph,
                         node: { _source: :describe_graph,
                                 _key: '290dccbd735b7163bc66bfb6c385240a28ad7f6a22123140f924f5d7c1ce0ec0',
                                 public_key: '030312fd8a77809402f2199a2b4e84b299f74060b715726303ed1e60ce611786d4' },
                         state: 'active',
                         policy: { fee: { base: { millisatoshis: 1000 }, rate: { parts_per_million: 1 } },
                                   htlc: { minimum: { millisatoshis: 1000 }, maximum: { millisatoshis: 247_500_000 },
                                           blocks: { delta: { minimum: 40 } } } } }] }
        )
      end
    end
  end

  context 'subscribe_channel_graph' do
    context 'complete' do
      it 'adapts' do
        channel_id = 118_747_255_865_345

        reference_raw = VCR.tape.replay('lightning.get_chan_info', chan_id: channel_id) do
          Lighstorm::Ports::GRPC.lightning.get_chan_info(chan_id: channel_id).to_h
        end

        Contract.expect(
          reference_raw,
          '6435cb37184004825e52beb929c7dd3def4ea690f9b5b17aedbefc3e6fbd21c7'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)
        end

        reference_adapted = described_class.get_chan_info(reference_raw)

        expect(reference_adapted).to eq(
          { _source: :get_chan_info,
            _key: 'f0d6de06aca8e43418a4ba5c336b2cd757a38c0d28322e84907dad5f11696226',
            id: '118747255865345',
            accounting: { capacity: { millisatoshis: 250_000_000 } },
            partners: [{ _source: :get_chan_info,
                         node: { _source: :get_chan_info,
                                 _key: 'fbce6d195972b53499122086de9b05244cef69393d8cb5d7402c2c60df736c1f',
                                 public_key: '02dc08e2bf7d833afd7b8dc0f8f4afd7cd64e12eb4683c8e7be95fdc13269942d6' },
                         state: 'active',
                         policy: { fee: { base: { millisatoshis: 1000 }, rate: { parts_per_million: 1 } },
                                   htlc: { minimum: { millisatoshis: 1000 }, maximum: { millisatoshis: 247_500_000 },
                                           blocks: { delta: { minimum: 40 } } } } },
                       { _source: :get_chan_info,
                         node: { _source: :get_chan_info,
                                 _key: '290dccbd735b7163bc66bfb6c385240a28ad7f6a22123140f924f5d7c1ce0ec0',
                                 public_key: '030312fd8a77809402f2199a2b4e84b299f74060b715726303ed1e60ce611786d4' },
                         state: 'active',
                         policy: { fee: { base: { millisatoshis: 1000 }, rate: { parts_per_million: 1 } },
                                   htlc: { minimum: { millisatoshis: 1000 }, maximum: { millisatoshis: 247_500_000 },
                                           blocks: { delta: { minimum: 40 } } } } }] }
        )

        raw = JSON.parse(TestData.read('spec/data/gossip/channel/sample-a.json'))

        Contract.expect(
          raw,
          'b653933617b1a914b6f5ad22b9469fed69b7f8a7107de113e0cea263a05575c0'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)
        end

        adapted = described_class.subscribe_channel_graph(raw)

        expect(adapted).to eq(
          { _source: :subscribe_channel_graph,
            _key: 'f0d6de06aca8e43418a4ba5c336b2cd757a38c0d28322e84907dad5f11696226',
            id: '118747255865345',
            accounting: { capacity: { millisatoshis: 250_000_000 } },
            partners: [{ _source: :subscribe_channel_graph,
                         node: { public_key: '02dc08e2bf7d833afd7b8dc0f8f4afd7cd64e12eb4683c8e7be95fdc13269942d6' },
                         policy: { _source: :subscribe_channel_graph,
                                   fee: { base: { millisatoshis: 1000 }, rate: { parts_per_million: 1 } },
                                   htlc: { minimum: { millisatoshis: 1000 }, maximum: { millisatoshis: 247_500_000 },
                                           blocks: { delta: { minimum: 40 } } } } },
                       { node: { public_key: '030312fd8a77809402f2199a2b4e84b299f74060b715726303ed1e60ce611786d4' } }] }
        )
      end
    end

    context 'missing fields' do
      it 'adapts' do
        channel_id = 197_912_093_065_217

        reference_raw = VCR.tape.replay('lightning.get_chan_info', chan_id: channel_id) do
          Lighstorm::Ports::GRPC.lightning.get_chan_info(chan_id: channel_id).to_h
        end

        Contract.expect(
          reference_raw,
          '6435cb37184004825e52beb929c7dd3def4ea690f9b5b17aedbefc3e6fbd21c7'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)
        end

        reference_adapted = described_class.get_chan_info(reference_raw)

        expect(reference_adapted).to eq(
          { _source: :get_chan_info,
            _key: '669c25d50862927bdcc1800f1c6a558c7166b7a54ad4374573632e07fb603af9',
            id: '197912093065217',
            accounting: { capacity: { millisatoshis: 250_000_000 } },
            partners: [{ _source: :get_chan_info,
                         node: { _source: :get_chan_info,
                                 _key: '290dccbd735b7163bc66bfb6c385240a28ad7f6a22123140f924f5d7c1ce0ec0',
                                 public_key: '030312fd8a77809402f2199a2b4e84b299f74060b715726303ed1e60ce611786d4' },
                         state: 'active',
                         policy: { fee: { base: { millisatoshis: 1000 }, rate: { parts_per_million: 1 } },
                                   htlc: { minimum: { millisatoshis: 1000 }, maximum: { millisatoshis: 247_500_000 },
                                           blocks: { delta: { minimum: 40 } } } } },
                       { _source: :get_chan_info,
                         node: { _source: :get_chan_info,
                                 _key: '790183426e81694c13758550dd4a9251ddc2dbeb1ea2b877ce3d808792df2dde',
                                 public_key: '03d70b5787c8be68bf63cd7b51d2074dfcc767dc975b7ac6cf1a17717ee12d8a44' },
                         state: 'active',
                         policy: { fee: { base: { millisatoshis: 1000 }, rate: { parts_per_million: 1 } },
                                   htlc: { minimum: { millisatoshis: 1000 }, maximum: { millisatoshis: 247_500_000 },
                                           blocks: { delta: { minimum: 40 } } } } }] }
        )

        raw = JSON.parse(TestData.read('spec/data/gossip/channel/sample-b.json'))

        Contract.expect(
          raw,
          '9c8fb3a4aac7b4cc94c965043cf5fd1f6111707be315a905279fb5d6b3c598b8'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)
        end

        adapted = described_class.subscribe_channel_graph(raw)

        expect(adapted).to eq(
          { _source: :subscribe_channel_graph,
            _key: '669c25d50862927bdcc1800f1c6a558c7166b7a54ad4374573632e07fb603af9',
            id: '197912093065217',
            accounting: { capacity: { millisatoshis: 250_000_000 } },
            partners: [{ _source: :subscribe_channel_graph,
                         node: { public_key: '030312fd8a77809402f2199a2b4e84b299f74060b715726303ed1e60ce611786d4' },
                         policy: { _source: :subscribe_channel_graph,
                                   fee: { base: { millisatoshis: 150 } },
                                   htlc: { minimum: { millisatoshis: 1000 }, maximum: { millisatoshis: 247_500_000 },
                                           blocks: { delta: { minimum: 40 } } } } },
                       { node: { public_key: '03d70b5787c8be68bf63cd7b51d2074dfcc767dc975b7ac6cf1a17717ee12d8a44' } }] }
        )
      end
    end

    context 'inactive' do
      it 'adapts' do
        raw = JSON.parse(TestData.read('spec/data/gossip/channel/sample-c.json'))

        Contract.expect(
          raw,
          '758dffdec71b227fbed3fa30c1ed44db5a01387de7de3433c65126f30c5943f8'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)
        end

        adapted = described_class.subscribe_channel_graph(raw)

        expect(adapted).to eq(
          { _source: :subscribe_channel_graph,
            _key: '669c25d50862927bdcc1800f1c6a558c7166b7a54ad4374573632e07fb603af9',
            id: '197912093065217',
            accounting: { capacity: { millisatoshis: 250_000_000 } },
            partners: [{ _source: :subscribe_channel_graph, node: { public_key: '030312fd8a77809402f2199a2b4e84b299f74060b715726303ed1e60ce611786d4' }, state: 'inactive' },
                       { node: { public_key: '03d70b5787c8be68bf63cd7b51d2074dfcc767dc975b7ac6cf1a17717ee12d8a44' } }] }
        )
      end
    end
  end
end
