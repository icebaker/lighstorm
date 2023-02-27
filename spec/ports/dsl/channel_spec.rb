# frozen_string_literal: true

require 'json'

require_relative '../../../ports/dsl/lighstorm'
require_relative '../../../ports/dsl/lighstorm/errors'

RSpec.describe Lighstorm::Channel do
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
        symbolize_keys(JSON.parse(File.read('spec/data/gossip/channel/29f0873593ae/dump.json')))
      end

      it do
        channel = described_class.adapt(dump: data)

        expect(Contract.for(channel._key)).to eq('String:50+')

        expect(channel.mine?).to be(false)

        expect(Contract.for(channel.id)).to eq('String:11..20')

        expect { channel.opened_at }.to raise_error(NotYourChannelError)
        expect { channel.up_at }.to raise_error(NotYourChannelError)
        expect { channel.state }.to raise_error(NotYourChannelError)
        expect { channel.active? }.to raise_error(NotYourChannelError)

        expect(Contract.for(channel.exposure)).to eq('String:0..10')

        expect(Contract.for(channel.accounting.capacity.millisatoshis)).to eq('Integer:0..10')

        expect { channel.accounting.sent }.to raise_error(NotYourChannelError)
        expect { channel.accounting.received }.to raise_error(NotYourChannelError)
        expect { channel.accounting.unsettled }.to raise_error(NotYourChannelError)

        expect(channel.partners.size).to eq(2)

        expect { channel.myself }.to raise_error(NotYourChannelError)
        expect { channel.partner }.to raise_error(NotYourChannelError)

        expect { channel.partners[0].accounting }.to raise_error(NotYourChannelError)
        expect(channel.partners[0].node.myself?).to be(false)

        expect(Contract.for(channel.partners[0].node.public_key)).to eq('String:50+')

        expect(Contract.for(channel.partners[0].policy.fee.base.millisatoshis)).to eq('Integer:0..10')
        expect(Contract.for(channel.partners[0].policy.fee.rate.parts_per_million)).to eq('Integer:0..10')
        expect(Contract.for(channel.partners[0].policy.htlc.minimum.millisatoshis)).to eq('Integer:0..10')
        expect(Contract.for(channel.partners[0].policy.htlc.maximum.millisatoshis)).to eq('Integer:0..10')

        expect { channel.partners[1].accounting }.to raise_error(NotYourChannelError)
        expect(channel.partners[1].node.myself?).to be(false)

        expect(Contract.for(channel.partners[1].node.public_key)).to eq('String:50+')

        expect(Contract.for(channel.partners[1].policy.fee.base.millisatoshis)).to eq('Integer:0..10')
        expect(Contract.for(channel.partners[1].policy.fee.rate.parts_per_million)).to eq('Integer:0..10')
        expect(Contract.for(channel.partners[1].policy.htlc.minimum.millisatoshis)).to eq('Integer:0..10')
        expect(Contract.for(channel.partners[1].policy.htlc.maximum.millisatoshis)).to eq('Integer:0..10')

        expect(Contract.for(channel.to_h)).to eq(
          { _key: 'String:50+',
            accounting: { capacity: { millisatoshis: 'Integer:0..10' } },
            id: 'String:11..20',
            partners: [
              { node: {
                  _key: 'String:50+',
                  platform: { blockchain: 'String:0..10', network: 'String:0..10' },
                  public_key: 'String:50+'
                },
                policy: {
                  fee: { base: { millisatoshis: 'Integer:0..10' },
                         rate: { parts_per_million: 'Integer:0..10' } },
                  htlc: { blocks: { delta: { minimum: 'Integer:0..10' } },
                          maximum: { millisatoshis: 'Integer:0..10' },
                          minimum: { millisatoshis: 'Integer:0..10' } }
                },
                state: 'String:0..10' },
              { node: {
                  _key: 'String:50+',
                  platform: { blockchain: 'String:0..10', network: 'String:0..10' },
                  public_key: 'String:50+'
                },
                policy: {
                  fee: { base: { millisatoshis: 'Integer:0..10' },
                         rate: { parts_per_million: 'Integer:0..10' } },
                  htlc: { blocks: { delta: { minimum: 'Integer:0..10' } },
                          maximum: { millisatoshis: 'Integer:0..10' },
                          minimum: { millisatoshis: 'Integer:0..10' } }
                },
                state: 'String:0..10' }
            ] }
        )
      end
    end

    context 'gossip' do
      let(:data) do
        JSON.parse(File.read('spec/data/gossip/channel/29f0873593ae/gossip.json'))
      end

      it do
        channel = described_class.adapt(gossip: data)

        expect(Contract.for(channel.to_h)).to eq(
          { _key: 'String:50+',
            id: 'String:11..20',
            partners: [
              { node: { _key: 'Nil', public_key: 'String:50+' },
                policy: {
                  fee: {
                    rate: { parts_per_million: 'Integer:0..10' }
                  },
                  htlc: { blocks: { delta: { minimum: 'Integer:0..10' } },
                          maximum: { millisatoshis: 'Integer:0..10' },
                          minimum: { millisatoshis: 'Integer:0..10' } }
                },
                state: 'Nil' },
              { node: {
                  _key: 'Nil',
                  public_key: 'String:50+'
                },
                state: 'Nil' }
            ] }
        )
      end
    end
  end
end
