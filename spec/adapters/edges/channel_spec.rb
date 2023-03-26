# frozen_string_literal: true

require 'json'

require_relative '../../../adapters/edges/channel'
require_relative '../../../ports/grpc'

RSpec.describe Lighstorm::Adapter::Channel do
  context 'list_channels' do
    it 'adapts' do
      raw = VCR.tape.replay('lightning.list_channels.channels.first') do
        Lighstorm::Ports::GRPC.lightning.list_channels.channels.first.to_h
      end

      Contract.expect(
        raw,
        '9e7565ade59707bbc8e6276b6773e98bd446ac6761ec1d4f3a474caf1cd2d2f2'
      ) do |actual, expected|
        expect(actual.hash).to eq(expected.hash)
        expect(actual.contract).to eq(expected.contract)
      end

      at = Time.new(2023, 2, 14, 13, 21, 0)

      adapted = described_class.list_channels(raw, at)

      Contract.expect(
        adapted,
        '78638b130b0ecc2cae35f36adeb0a393b9d81c5c70a3285ae4c50c15374f1247'
      ) do |actual, expected|
        expect(actual.hash).to eq(expected.hash)
        expect(actual.contract).to eq(expected.contract)
      end
    end
  end

  context 'get_chan_info' do
    context 'my channel' do
      it 'adapts' do
        channel_id = 850_099_509_773_795_329

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
            _key: '45e0a276f13bdcb471a0d0518433c76c76dd4b0c5e1f61d19a3878bafb50c771',
            id: '850099509773795329',
            accounting: { capacity: { millisatoshis: 6_300_000_000 } },
            partners: [{ _source: :get_chan_info,
                         node: { _source: :get_chan_info,
                                 _key: '3a403058cd81927fe53073367f46d01b0a52bec6705b0ae0d20b5385973c14b0',
                                 public_key: '026165850492521f4ac8abd9bd8088123446d126f648ca35e60f88177dc149ceb2' },
                         state: 'active',
                         policy: { fee: { base: { millisatoshis: 0 }, rate: { parts_per_million: 1 } },
                                   htlc: { minimum: { millisatoshis: 1000 }, maximum: { millisatoshis: 6_237_000_000 },
                                           blocks: { delta: { minimum: 40 } } } } },
                       { _source: :get_chan_info,
                         node: { _source: :get_chan_info,
                                 _key: '32564df7a5aa5e3fbef3056c77ba6531362478a80c12b0fa32c63f6bd02fde78',
                                 public_key: '02d3c80335a8ccb2ed364c06875f32240f36f7edb37d80f8dbe321b4c364b6e997' },
                         state: 'active',
                         policy: { fee: { base: { millisatoshis: 0 }, rate: { parts_per_million: 5 } },
                                   htlc: { minimum: { millisatoshis: 1000 }, maximum: { millisatoshis: 6_045_000_000 },
                                           blocks: { delta: { minimum: 40 } } } } }] }
        )
      end
    end

    context 'other channel' do
      it 'adapts' do
        channel_id = 836_907_569_272_651_777

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
            _key: '956d9e082e428c0897882987ae0cf0f2d8179c7a36da8da4e1085d4f71059d6e',
            id: '836907569272651777',
            accounting: { capacity: { millisatoshis: 1_000_000_000 } },
            partners: [{ _source: :get_chan_info,
                         node: { _source: :get_chan_info,
                                 _key: '3a403058cd81927fe53073367f46d01b0a52bec6705b0ae0d20b5385973c14b0',
                                 public_key: '026165850492521f4ac8abd9bd8088123446d126f648ca35e60f88177dc149ceb2' },
                         state: 'active',
                         policy: { fee: { base: { millisatoshis: 0 }, rate: { parts_per_million: 1 } },
                                   htlc: { minimum: { millisatoshis: 1000 }, maximum: { millisatoshis: 990_000_000 },
                                           blocks: { delta: { minimum: 20 } } } } },
                       { _source: :get_chan_info,
                         node: { _source: :get_chan_info,
                                 _key: '7aeb224e0e0b4c8d376533e6b102fdaabb0dc5b3ee71658aee96ef80d5c44997',
                                 public_key: '0265e622be131c39ae19e8a9d1195eb509149603f8bf882cd1b8f9707e019b7e7b' },
                         state: 'active',
                         policy: { fee: { base: { millisatoshis: 1000 }, rate: { parts_per_million: 1 } },
                                   htlc: { minimum: { millisatoshis: 1000 }, maximum: { millisatoshis: 990_000_000 },
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
          '68abed525be6bf7a3871f36465ddceae5737f24262b6a6dbb3e0380966705037'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)
        end

        adapted = described_class.describe_graph(raw)

        expect(adapted).to eq(
          { _source: :describe_graph,
            _key: 'f9c6a9a868b2166f2af9fdab15b4b27cccee1b82a781e109168ef9e08d8bb7eb',
            id: '553951550347608065',
            exposure: 'public',
            accounting: { capacity: { millisatoshis: 37_200_000 } },
            partners: [{ _source: :describe_graph,
                         node: { _source: :describe_graph,
                                 _key: 'ea4cfee7f825f79bce1c96431ec506ddbb6eb6ee37d3f48f1fe9a2df87b19f7d',
                                 public_key: '03bd3466efd4a7306b539e2314e69efc6b1eaee29734fcedd78cf81b1dde9fedf8' } },
                       { _source: :describe_graph,
                         node: { _source: :describe_graph,
                                 _key: '9c642c27223c22ca0e265ca357db1abaf6846cace4518cd27a6c22d220b341cd',
                                 public_key: '03c3d14714b78f03fd6ea4997c2b540a4139258249ea1d625c03b68bb82f85d0ea' } }] }
        )
      end
    end
  end

  context 'subscribe_channel_graph' do
    context 'complete' do
      it 'adapts' do
        channel_id = 837_471_618_647_916_545

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
            _key: '36c34f134dd6b41c4bb9c8a84e90e6903d9fff663af6cfe2ea68acdca5660f46',
            id: '837471618647916545',
            accounting: { capacity: { millisatoshis: 5_000_000_000 } },
            partners: [{ _source: :get_chan_info,
                         node: { _source: :get_chan_info,
                                 _key: 'de2939d174ddd01e051a5b05e3e2e40479d0dfd16ee5295c0b4985890a603ffc',
                                 public_key: '0201af659a3986832bb5bf2493c537cee9f7d62a7bff5d0a68176c1d60df931cf7' },
                         state: 'active',
                         policy: { fee: { base: { millisatoshis: 0 }, rate: { parts_per_million: 700 } },
                                   htlc: { minimum: { millisatoshis: 1000 }, maximum: { millisatoshis: 4_950_000_000 },
                                           blocks: { delta: { minimum: 40 } } } } },
                       { _source: :get_chan_info,
                         node: { _source: :get_chan_info,
                                 _key: '713519e5aca513a070deedc0520be905e0fc3e36f555c33f977b6c369b7d76fb',
                                 public_key: '037659a0ac8eb3b8d0a720114efc861d3a940382dcfa1403746b4f8f6b2e8810ba' },
                         state: 'active',
                         policy: { fee: { base: { millisatoshis: 1000 }, rate: { parts_per_million: 300 } },
                                   htlc: { minimum: { millisatoshis: 1000 }, maximum: { millisatoshis: 4_950_000_000 },
                                           blocks: { delta: { minimum: 144 } } } } }] }
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
            _key: '36c34f134dd6b41c4bb9c8a84e90e6903d9fff663af6cfe2ea68acdca5660f46',
            id: '837471618647916545',
            accounting: { capacity: { millisatoshis: 5_000_000_000 } },
            partners: [{ _source: :subscribe_channel_graph,
                         node: { public_key: '037659a0ac8eb3b8d0a720114efc861d3a940382dcfa1403746b4f8f6b2e8810ba' },
                         policy: { _source: :subscribe_channel_graph,
                                   fee: { base: { millisatoshis: 1000 }, rate: { parts_per_million: 300 } },
                                   htlc: { minimum: { millisatoshis: 1000 }, maximum: { millisatoshis: 4_950_000_000 },
                                           blocks: { delta: { minimum: 144 } } } } },
                       { node: { public_key: '0201af659a3986832bb5bf2493c537cee9f7d62a7bff5d0a68176c1d60df931cf7' } }] }
        )
      end
    end

    context 'missing fields' do
      it 'adapts' do
        channel_id = 798_835_879_549_927_425

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
            _key: 'd81f408d0cfeac62db4c2d11bbad13d9c4370ffbdca6c1053a50c38560129735',
            id: '798835879549927425',
            accounting: { capacity: { millisatoshis: 400_000_000 } },
            partners: [{ _source: :get_chan_info,
                         node: { _source: :get_chan_info,
                                 _key: '88e2a6fc09e5abe81b7d23e69a471e5bc0940be89c3b3d2de809121da6d5e34e',
                                 public_key: '0207ed361128e101a16605fd8e7b491e2d28f7db1677363c9712a3907523a414d2' },
                         state: 'active',
                         policy: { fee: { base: { millisatoshis: 100 }, rate: { parts_per_million: 24 } },
                                   htlc: { minimum: { millisatoshis: 1000 }, maximum: { millisatoshis: 396_000_000 },
                                           blocks: { delta: { minimum: 40 } } } } },
                       { _source: :get_chan_info,
                         node: { _source: :get_chan_info,
                                 _key: '3a403058cd81927fe53073367f46d01b0a52bec6705b0ae0d20b5385973c14b0',
                                 public_key: '026165850492521f4ac8abd9bd8088123446d126f648ca35e60f88177dc149ceb2' },
                         state: 'active',
                         policy: { fee: { base: { millisatoshis: 0 }, rate: { parts_per_million: 1 } },
                                   htlc: { minimum: { millisatoshis: 1000 }, maximum: { millisatoshis: 396_000_000 },
                                           blocks: { delta: { minimum: 20 } } } } }] }
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
            _key: 'd81f408d0cfeac62db4c2d11bbad13d9c4370ffbdca6c1053a50c38560129735',
            id: '798835879549927425',
            accounting: { capacity: { millisatoshis: 400_000_000 } },
            partners: [{ _source: :subscribe_channel_graph,
                         node: { public_key: '0207ed361128e101a16605fd8e7b491e2d28f7db1677363c9712a3907523a414d2' },
                         policy: { _source: :subscribe_channel_graph,
                                   fee: { base: { millisatoshis: 150 } },
                                   htlc: { minimum: { millisatoshis: 1000 }, maximum: { millisatoshis: 396_000_000 },
                                           blocks: { delta: { minimum: 40 } } } } },
                       { node: { public_key: '026165850492521f4ac8abd9bd8088123446d126f648ca35e60f88177dc149ceb2' } }] }
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
            _key: '31268bb02f9536cb951e4c2f7785e4c6e04274f59d6e9c18315f6a6d3725c685',
            id: '838301749944647681',
            accounting: { capacity: { millisatoshis: 350_000_000 } },
            partners: [{ _source: :subscribe_channel_graph, node: { public_key: '023ad453e0ab3767112427b654247bbdd337864532d38967485ab622d05f5d26db' }, state: 'inactive' },
                       { node: { public_key: '03055d3f08f9bf7725dc0644192f045e3466995db33c7464b0e32fb3542d866b87' } }] }
        )
      end
    end
  end
end
