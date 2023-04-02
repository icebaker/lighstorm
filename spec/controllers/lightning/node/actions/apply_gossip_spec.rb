# frozen_string_literal: true

require 'json'

require_relative '../../../../../controllers/lightning/node'
require_relative '../../../../../controllers/lightning/node/find_by_public_key'

require_relative '../../../../../models/lightning/nodes/node'

require_relative '../../../../../ports/dsl/lighstorm/errors'

RSpec.describe Lighstorm::Model::Lightning::Node do
  describe '.apply!' do
    let(:node) do
      data = Lighstorm::Controller::Lightning::Node::FindByPublicKey.data(
        Lighstorm::Controller::Lightning::Node.components,
        public_key
      ) do |fetch|
        VCR.tape.replay("Controller::Lightning::Node.find_by_public_key/#{public_key}") { fetch.call }
      end

      described_class.new(data, Lighstorm::Controller::Lightning::Node.components)
    end

    context 'complete with changes' do
      let(:public_key) { '02dc08e2bf7d833afd7b8dc0f8f4afd7cd64e12eb4683c8e7be95fdc13269942d6' }

      it 'applies the gossip' do
        previous_to_h = node.to_h
        previous_dump = node.dump

        expect(previous_to_h).to eq(
          { _key: 'fbce6d195972b53499122086de9b05244cef69393d8cb5d7402c2c60df736c1f',
            public_key: '02dc08e2bf7d833afd7b8dc0f8f4afd7cd64e12eb4683c8e7be95fdc13269942d6',
            alias: 'bob',
            color: '#3399ff',
            platform: { blockchain: 'bitcoin', network: 'regtest',
                        lightning: { implementation: 'lnd', version: '0.15.5-beta commit=v0.15.5-beta' } } }
        )

        expect(previous_dump).to eq(
          { _source: :get_info,
            _key: 'fbce6d195972b53499122086de9b05244cef69393d8cb5d7402c2c60df736c1f',
            public_key: '02dc08e2bf7d833afd7b8dc0f8f4afd7cd64e12eb4683c8e7be95fdc13269942d6',
            alias: 'bob',
            color: '#3399ff',
            platform: { blockchain: 'bitcoin', network: 'regtest',
                        lightning: { implementation: 'lnd', version: '0.15.5-beta commit=v0.15.5-beta' } },
            myself: true }
        )

        gossip = JSON.parse(TestData.read('spec/data/gossip/node/sample-a.json'))

        expect(node.alias).not_to eq('SampleNode')
        expect(node.color).not_to eq('#ff5002')

        diff = node.apply!(gossip: gossip)

        expect(node.alias).to eq('SampleNode')
        expect(node.color).to eq('#ff5002')

        expect(diff).to eq(
          [{ path: [:alias], from: 'bob', to: 'SampleNode' },
           { path: [:color], from: '#3399ff', to: '#ff5002' }]
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
          { _key: 'fbce6d195972b53499122086de9b05244cef69393d8cb5d7402c2c60df736c1f',
            public_key: '02dc08e2bf7d833afd7b8dc0f8f4afd7cd64e12eb4683c8e7be95fdc13269942d6',
            alias: 'SampleNode',
            color: '#ff5002' }
        )

        expect(node.dump).to eq(
          { _source: :subscribe_channel_graph,
            _key: 'fbce6d195972b53499122086de9b05244cef69393d8cb5d7402c2c60df736c1f',
            public_key: '02dc08e2bf7d833afd7b8dc0f8f4afd7cd64e12eb4683c8e7be95fdc13269942d6',
            alias: 'SampleNode',
            color: '#ff5002' }
        )

        expect { node.apply!(gossip: gossip) }.not_to raise_error
      end
    end
  end
end
