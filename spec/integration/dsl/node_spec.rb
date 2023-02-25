# frozen_string_literal: true

require_relative '../../../ports/dsl/lighstorm'
require_relative '../../../ports/dsl/lighstorm/errors'

RSpec.describe 'Integration Tests' do
  context 'Node' do
    context 'fast' do
      context 'myself' do
        it do
          check_integration!

          myself = Lighstorm::Node.myself

          expect(Contract.for(myself._key)).to eq('String:50+')
          expect(Contract.for(myself.alias)).to eq('String:11..20')
          expect(Contract.for(myself.public_key)).to eq('String:50+')
          expect(Contract.for(myself.color)).to eq('String:0..10')
          expect(myself.myself?).to be(true)

          expect(Contract.for(myself.platform.blockchain)).to eq('String:0..10')
          expect(Contract.for(myself.platform.network)).to eq('String:0..10')
          expect(Contract.for(myself.platform.lightning.implementation)).to eq('String:0..10')
          expect(Contract.for(myself.platform.lightning.version)).to eq('String:31..40')

          channels = myself.channels

          expect(myself.channels.size).to be > 0
          expect(myself.channels.size).to be < 10_000

          channel = channels.first

          expect(channel.mine?).to be(true)

          expect(Contract.for(channel.id)).to eq('String:11..20')
          expect(Contract.for(channel.opened_at)).to eq('Time')

          expect(Contract.for(myself.to_h)).to eq(
            { _key: 'String:50+',
              alias: 'String:11..20',
              color: 'String:0..10',
              platform: {
                blockchain: 'String:0..10',
                network: 'String:0..10',
                lightning: {
                  implementation: 'String:0..10',
                  version: 'String:31..40'
                }
              },
              public_key: 'String:50+' }
          )
        end
      end

      context 'find_by_public_key' do
        it do
          check_integration!

          find = Lighstorm::Node.find_by_public_key(
            '024bfaf0cabe7f874fd33ebf7c6f4e5385971fc504ef3f492432e9e3ec77e1b5cf'
          )

          expect(Contract.for(find._key)).to eq('String:50+')
          expect(Contract.for(find.alias)).to eq('String:11..20')
          expect(Contract.for(find.public_key)).to eq('String:50+')
          expect(Contract.for(find.color)).to eq('String:0..10')
          expect(Contract.for(find.myself?)).to be('Boolean')

          expect(Contract.for(find.platform.blockchain)).to eq('String:0..10')
          expect(Contract.for(find.platform.network)).to eq('String:0..10')

          expect(Contract.for(find.to_h)).to eq(
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
    end

    context 'slow' do
      context 'graph' do
        it do
          check_integration!(slow: true)

          expect(Lighstorm::Node.all.size).to be > 10_000

          nodes = Lighstorm::Node.all(limit: 10)

          expect(nodes.size).to eq(10)

          node = nodes.first

          expect(Contract.for(node._key)).to eq('String:50+')
          expect(Contract.for(node.alias)).to eq('String:0..10')
          expect(Contract.for(node.public_key)).to eq('String:50+')
          expect(Contract.for(node.color)).to eq('String:0..10')
          expect(Contract.for(node.myself?)).to be('Boolean')

          expect(Contract.for(node.platform.blockchain)).to eq('String:0..10')
          expect(Contract.for(node.platform.network)).to eq('String:0..10')

          expect(Contract.for(node.to_h)).to eq(
            { _key: 'String:50+',
              alias: 'String:0..10',
              color: 'String:0..10',
              platform: {
                blockchain: 'String:0..10',
                network: 'String:0..10'
              },
              public_key: 'String:50+' }
          )
        end
      end
    end
  end
end
