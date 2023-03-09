# frozen_string_literal: true

require 'json'

require_relative '../../../../controllers/node/find_by_public_key'

require_relative '../../../../models/nodes/node'

require_relative '../../../../ports/dsl/lighstorm/errors'

RSpec.describe Lighstorm::Models::Node do
  describe '.apply!' do
    let(:node) do
      data = Lighstorm::Controllers::Node::FindByPublicKey.data(public_key) do |fetch|
        VCR.tape.replay("Controllers::Node.find_by_public_key/#{public_key}") { fetch.call }
      end

      described_class.new(data)
    end

    context 'complete with changes' do
      let(:public_key) { '023c047f51141b345db60fb4bf7a6a863ed9e010fa8eaba0d596322565a6b9a73b' }

      it 'applies the gossip' do
        previous_to_h = node.to_h
        previous_dump = node.dump

        expect(previous_to_h).to eq(
          { _key: '8b8b460416bc384260ca166233827f361a0c0da7b632c68a2720e08fbe3f528c',
            public_key: '023c047f51141b345db60fb4bf7a6a863ed9e010fa8eaba0d596322565a6b9a73b',
            alias: 'Gerdtrudroepke',
            color: '#ff5000',
            platform: { blockchain: 'bitcoin', network: 'mainnet' } }
        )

        expect(previous_dump).to eq(
          { _source: :get_node_info,
            _key: '8b8b460416bc384260ca166233827f361a0c0da7b632c68a2720e08fbe3f528c',
            public_key: '023c047f51141b345db60fb4bf7a6a863ed9e010fa8eaba0d596322565a6b9a73b',
            alias: 'Gerdtrudroepke',
            color: '#ff5000',
            platform: { blockchain: 'bitcoin', network: 'mainnet' },
            myself: false }
        )

        gossip = JSON.parse(TestData.read('spec/data/gossip/node/sample-a.json'))

        expect(node.alias).not_to eq('SampleNode')
        expect(node.color).not_to eq('#ff5002')

        diff = node.apply!(gossip: gossip)

        expect(node.alias).to eq('SampleNode')
        expect(node.color).to eq('#ff5002')

        expect(diff).to eq(
          [{ path: [:alias], from: 'Gerdtrudroepke', to: 'SampleNode' },
           { path: [:color], from: '#ff5000', to: '#ff5002' }]
        )

        expect(node.to_h).not_to eq(previous_to_h)
        expect(node.dump).not_to eq(previous_dump)
      end
    end

    context 'from empty' do
      it 'applies the gossip' do
        gossip = JSON.parse(TestData.read('spec/data/gossip/node/sample-a.json'))

        node = described_class.adapt(gossip: gossip)

        expect(node.to_h).to eq(
          { _key: '8b8b460416bc384260ca166233827f361a0c0da7b632c68a2720e08fbe3f528c',
            public_key: '023c047f51141b345db60fb4bf7a6a863ed9e010fa8eaba0d596322565a6b9a73b',
            alias: 'SampleNode',
            color: '#ff5002' }
        )

        expect(node.dump).to eq(
          { _source: :subscribe_channel_graph,
            _key: '8b8b460416bc384260ca166233827f361a0c0da7b632c68a2720e08fbe3f528c',
            public_key: '023c047f51141b345db60fb4bf7a6a863ed9e010fa8eaba0d596322565a6b9a73b',
            alias: 'SampleNode',
            color: '#ff5002' }
        )

        expect { node.apply!(gossip: gossip) }.not_to raise_error
      end
    end
  end
end
