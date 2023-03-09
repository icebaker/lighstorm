# frozen_string_literal: true

require 'json'

require_relative '../../../ports/dsl/lighstorm'
require_relative '../../../ports/dsl/lighstorm/errors'

RSpec.describe Lighstorm::Node do
  context 'adapts' do
    context 'errors' do
      it 'raises error' do
        expect { described_class.adapt(dump: {}, gossip: {}) }.to raise_error(
          TooManyArgumentsError, 'you need to pass gossip: or dump:, not both'
        )

        expect { described_class.adapt }.to raise_error(
          ArgumentError, 'missing gossip: or dump:'
        )
      end
    end

    context 'dump' do
      let(:data) do
        symbolize_keys(JSON.parse(TestData.read('spec/data/gossip/node/4dec8c315434/dump.json')))
      end

      it do
        node = described_class.adapt(dump: data)

        expect(Contract.for(node._key)).to eq('String:50+')
        expect(Contract.for(node.alias)).to eq('String:11..20')
        expect(Contract.for(node.public_key)).to eq('String:50+')
        expect(Contract.for(node.color)).to eq('String:0..10')
        expect(Contract.for(node.myself?)).to be('Boolean')

        expect(Contract.for(node.platform.blockchain)).to eq('String:0..10')
        expect(Contract.for(node.platform.network)).to eq('String:0..10')

        expect(Contract.for(node.to_h)).to eq(
          { _key: 'String:50+',
            alias: 'String:11..20',
            color: 'String:0..10',
            platform: {
              blockchain: 'String:0..10',
              network: 'String:0..10'
            },
            public_key: 'String:50+' }
        )
      end
    end

    context 'gossip' do
      let(:data) do
        JSON.parse(TestData.read('spec/data/gossip/node/4dec8c315434/gossip.json'))
      end

      it do
        node = described_class.adapt(gossip: data)

        expect(Contract.for(node._key)).to eq('String:50+')
        expect(Contract.for(node.alias)).to eq('String:11..20')
        expect(Contract.for(node.public_key)).to eq('String:50+')
        expect(Contract.for(node.color)).to eq('String:0..10')
        expect(Contract.for(node.myself?)).to be('Boolean')

        expect(Contract.for(node.platform.blockchain)).to eq('Nil')
        expect(Contract.for(node.platform.network)).to eq('Nil')

        expect(Contract.for(node.to_h)).to eq(
          { _key: 'String:50+',
            alias: 'String:11..20',
            color: 'String:0..10',
            public_key: 'String:50+' }
        )
      end
    end
  end
end
