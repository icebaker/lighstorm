# frozen_string_literal: true

require_relative '../../../adapters/edges/channel'
require_relative '../../../ports/grpc'

RSpec.describe Lighstorm::Adapter::Channel do
  context 'list_channels' do
    it 'adapts' do
      raw = VCR.replay('lightning.list_channels.channels.first') do
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

      Contract.expect!(
        adapted,
        '56147059a033801f729c07d1a9e1d5395cc4ec3904356ed379d5bde366cd6dc8'
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

        raw = VCR.replay('lightning.get_chan_info', chan_id: channel_id) do
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
            accounting: { capacity: { milisatoshis: 6_300_000_000 } },
            partners: [{ _source: :get_chan_info,
                         node: { _source: :get_chan_info,
                                 _key: '3a403058cd81927fe53073367f46d01b0a52bec6705b0ae0d20b5385973c14b0',
                                 public_key: '026165850492521f4ac8abd9bd8088123446d126f648ca35e60f88177dc149ceb2' },
                         policy: { fee: { base: { milisatoshis: 0 }, rate: { parts_per_million: 1 } },
                                   htlc: { minimum: { milisatoshis: 1000 }, maximum: { milisatoshis: 6_237_000_000 },
                                           blocks: { delta: { minimum: 40 } } } } },
                       { _source: :get_chan_info,
                         node: { _source: :get_chan_info,
                                 _key: '32564df7a5aa5e3fbef3056c77ba6531362478a80c12b0fa32c63f6bd02fde78',
                                 public_key: '02d3c80335a8ccb2ed364c06875f32240f36f7edb37d80f8dbe321b4c364b6e997' },
                         policy: { fee: { base: { milisatoshis: 0 }, rate: { parts_per_million: 5 } },
                                   htlc: { minimum: { milisatoshis: 1000 }, maximum: { milisatoshis: 6_045_000_000 },
                                           blocks: { delta: { minimum: 40 } } } } }] }
        )
      end
    end

    context 'other channel' do
      it 'adapts' do
        channel_id = 836_907_569_272_651_777

        raw = VCR.replay('lightning.get_chan_info', chan_id: channel_id) do
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
            accounting: { capacity: { milisatoshis: 1_000_000_000 } },
            partners: [{ _source: :get_chan_info,
                         node: { _source: :get_chan_info,
                                 _key: '3a403058cd81927fe53073367f46d01b0a52bec6705b0ae0d20b5385973c14b0',
                                 public_key: '026165850492521f4ac8abd9bd8088123446d126f648ca35e60f88177dc149ceb2' },
                         policy: { fee: { base: { milisatoshis: 0 }, rate: { parts_per_million: 1 } },
                                   htlc: { minimum: { milisatoshis: 1000 }, maximum: { milisatoshis: 990_000_000 },
                                           blocks: { delta: { minimum: 20 } } } } },
                       { _source: :get_chan_info,
                         node: { _source: :get_chan_info,
                                 _key: '7aeb224e0e0b4c8d376533e6b102fdaabb0dc5b3ee71658aee96ef80d5c44997',
                                 public_key: '0265e622be131c39ae19e8a9d1195eb509149603f8bf882cd1b8f9707e019b7e7b' },
                         policy: { fee: { base: { milisatoshis: 1000 }, rate: { parts_per_million: 1 } },
                                   htlc: { minimum: { milisatoshis: 1000 }, maximum: { milisatoshis: 990_000_000 },
                                           blocks: { delta: { minimum: 40 } } } } }] }
        )
      end
    end
  end

  context 'describe_graph' do
    context 'first' do
      it 'adapts' do
        raw = VCR.replay('lightning.describe_graph.edges.first') do
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
            accounting: { capacity: { milisatoshis: 37_200_000 } },
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
end
