# frozen_string_literal: true

require_relative '../../../ports/dsl/lighstorm'
require_relative '../../../ports/dsl/lighstorm/errors'

RSpec.describe 'Integration Tests' do
  context 'Channel' do
    context 'fast' do
      context 'mine' do
        it do
          check_integration!

          mine = Lighstorm::Channel.mine

          expect(mine.size).to be > 0
          expect(mine.size).to be < 10_000

          channel = mine.first

          expect(channel.mine?).to be(true)

          expect(Contract.for(channel._key)).to eq('String:50+')
          expect(Contract.for(channel.id)).to eq('String:11..20')
          expect(Contract.for(channel.opened_at)).to eq('DateTime')
          expect(Contract.for(channel.up_at)).to eq('DateTime')
          expect(Contract.for(channel.state)).to eq('String:0..10')
          expect(Contract.for(channel.active?)).to eq('Boolean')
          expect(Contract.for(channel.exposure)).to eq('String:0..10')

          expect(Contract.for(channel.transaction.funding.id)).to eq('String:50+')
          expect(Contract.for(channel.transaction.funding.index)).to eq('Integer:0..10')

          expect(Contract.for(channel.accounting.capacity.milisatoshis)).to eq('Integer:0..10')
          expect(Contract.for(channel.accounting.sent.milisatoshis)).to eq('Integer:11..20')
          expect(Contract.for(channel.accounting.received.milisatoshis)).to eq('Integer:11..20')
          expect(Contract.for(channel.accounting.unsettled.milisatoshis)).to eq('Integer:0..10')

          expect(channel.partners.size).to eq(2)

          expect(channel.myself.node.myself?).to be(true)
          expect(channel.myself.node.public_key).to eq(channel.partners[0].node.public_key)

          expect(Contract.for(channel.myself.accounting.balance.milisatoshis)).to eq('Integer:0..10')
          expect(Contract.for(channel.myself.node.public_key)).to eq('String:50+')

          expect(Contract.for(channel.myself.policy.fee.base.milisatoshis)).to eq('Integer:0..10')
          expect(Contract.for(channel.myself.policy.fee.rate.parts_per_million)).to eq('Integer:0..10')
          expect(Contract.for(channel.myself.policy.htlc.minimum.milisatoshis)).to eq('Integer:0..10')
          expect(Contract.for(channel.myself.policy.htlc.maximum.milisatoshis)).to eq('Integer:0..10')
          expect(Contract.for(channel.myself.policy.htlc.blocks.delta.minimum)).to eq('Integer:0..10')

          expect(channel.partner.node.myself?).to be(false)
          expect(channel.partner.node.public_key).to eq(channel.partners[1].node.public_key)

          expect(Contract.for(channel.partner.accounting.balance.milisatoshis)).to eq('Integer:0..10')
          expect(Contract.for(channel.partner.node.public_key)).to eq('String:50+')

          expect(Contract.for(channel.partner.policy.fee.base.milisatoshis)).to eq('Integer:0..10')
          expect(Contract.for(channel.partner.policy.fee.rate.parts_per_million)).to eq('Integer:0..10')
          expect(Contract.for(channel.partner.policy.htlc.minimum.milisatoshis)).to eq('Integer:0..10')
          expect(Contract.for(channel.partner.policy.htlc.maximum.milisatoshis)).to eq('Integer:0..10')
        end
      end

      context 'find_by_id' do
        it do
          check_integration!

          channel = Lighstorm::Channel.find_by_id('553951550347608065')

          expect(Contract.for(channel._key)).to eq('String:50+')

          expect(channel.mine?).to be(false)

          expect(Contract.for(channel.id)).to eq('String:11..20')

          expect { channel.opened_at }.to raise_error(NotYourChannelError)
          expect { channel.up_at }.to raise_error(NotYourChannelError)
          expect { channel.state }.to raise_error(NotYourChannelError)
          expect { channel.active? }.to raise_error(NotYourChannelError)

          expect(Contract.for(channel.exposure)).to eq('String:0..10')

          expect(Contract.for(channel.accounting.capacity.milisatoshis)).to eq('Integer:0..10')

          expect { channel.accounting.sent }.to raise_error(NotYourChannelError)
          expect { channel.accounting.received }.to raise_error(NotYourChannelError)
          expect { channel.accounting.unsettled }.to raise_error(NotYourChannelError)

          expect(channel.partners.size).to eq(2)

          expect { channel.myself }.to raise_error(NotYourChannelError)
          expect { channel.partner }.to raise_error(NotYourChannelError)

          expect { channel.partners[0].accounting }.to raise_error(NotYourChannelError)
          expect(channel.partners[0].node.myself?).to be(false)

          expect(Contract.for(channel.partners[0].node.public_key)).to eq('String:50+')

          expect(Contract.for(channel.partners[0].policy.fee.base)).to eq('Nil')
          expect(Contract.for(channel.partners[0].policy.fee.rate)).to eq('Nil')
          expect(Contract.for(channel.partners[0].policy.htlc.minimum)).to eq('Nil')
          expect(Contract.for(channel.partners[0].policy.htlc.maximum)).to eq('Nil')
          expect(Contract.for(channel.partners[0].policy.htlc.blocks.delta.minimum)).to eq('Nil')

          expect { channel.partners[1].accounting }.to raise_error(NotYourChannelError)
          expect(channel.partners[1].node.myself?).to be(false)

          expect(Contract.for(channel.partners[1].node.public_key)).to eq('String:50+')

          expect(Contract.for(channel.partners[1].policy.fee.base)).to eq('Nil')
          expect(Contract.for(channel.partners[1].policy.fee.rate)).to eq('Nil')
          expect(Contract.for(channel.partners[1].policy.htlc.minimum)).to eq('Nil')
          expect(Contract.for(channel.partners[1].policy.htlc.maximum)).to eq('Nil')
          expect(Contract.for(channel.partners[1].policy.htlc.blocks.delta.minimum)).to eq('Nil')

          expect(Contract.for(channel.to_h)).to eq(
            { _key: 'String:50+',
              accounting: {
                capacity: { milisatoshis: 'Integer:0..10' }
              },
              id: 'String:11..20',
              partners: [
                { node: {
                    _key: 'String:50+',
                    alias: 'String:0..10',
                    color: 'String:0..10',
                    platform: { blockchain: 'String:0..10', network: 'String:0..10' },
                    public_key: 'String:50+'
                  },
                  state: 'Nil' },
                { node: {
                    _key: 'String:50+',
                    alias: 'String:0..10',
                    color: 'String:0..10',
                    platform: { blockchain: 'String:0..10', network: 'String:0..10' },
                    public_key: 'String:50+'
                  },
                  state: 'Nil' }
              ] }
          )
        end
      end
    end

    context 'slow' do
      context 'graph' do
        it do
          check_integration!(slow: true)

          channels = Lighstorm::Channel.all

          expect(channels.size).to be > 50_000

          channels = Lighstorm::Channel.all(limit: 10)

          expect(channels.size).to eq(10)

          channel = channels.first

          expect(Contract.for(channel._key)).to eq('String:50+')

          expect(channel.mine?).to be(false)

          expect(Contract.for(channel.id)).to eq('String:11..20')

          expect { channel.opened_at }.to raise_error(NotYourChannelError)
          expect { channel.up_at }.to raise_error(NotYourChannelError)
          expect { channel.state }.to raise_error(NotYourChannelError)
          expect { channel.active? }.to raise_error(NotYourChannelError)

          expect(Contract.for(channel.exposure)).to eq('String:0..10')

          expect(Contract.for(channel.accounting.capacity.milisatoshis)).to eq('Integer:0..10')

          expect { channel.accounting.sent }.to raise_error(NotYourChannelError)
          expect { channel.accounting.received }.to raise_error(NotYourChannelError)
          expect { channel.accounting.unsettled }.to raise_error(NotYourChannelError)

          expect(channel.partners.size).to eq(2)

          expect { channel.myself }.to raise_error(NotYourChannelError)
          expect { channel.partner }.to raise_error(NotYourChannelError)

          expect { channel.partners[0].accounting }.to raise_error(NotYourChannelError)
          expect(channel.partners[0].node.myself?).to be(false)

          expect(Contract.for(channel.partners[0].node.public_key)).to eq('String:50+')

          expect(Contract.for(channel.partners[0].policy.fee.base)).to eq('Nil')
          expect(Contract.for(channel.partners[0].policy.fee.rate)).to eq('Nil')
          expect(Contract.for(channel.partners[0].policy.htlc.minimum)).to eq('Nil')
          expect(Contract.for(channel.partners[0].policy.htlc.maximum)).to eq('Nil')
          expect(Contract.for(channel.partners[0].policy.htlc.blocks.delta.minimum)).to eq('Nil')

          expect { channel.partners[1].accounting }.to raise_error(NotYourChannelError)
          expect(channel.partners[1].node.myself?).to be(false)

          expect(Contract.for(channel.partners[1].node.public_key)).to eq('String:50+')

          expect(Contract.for(channel.partners[1].policy.fee.base)).to eq('Nil')
          expect(Contract.for(channel.partners[1].policy.fee.rate)).to eq('Nil')
          expect(Contract.for(channel.partners[1].policy.htlc.minimum)).to eq('Nil')
          expect(Contract.for(channel.partners[1].policy.htlc.maximum)).to eq('Nil')
          expect(Contract.for(channel.partners[1].policy.htlc.blocks.delta.minimum)).to eq('Nil')

          expect(Contract.for(channel.to_h)).to eq(
            { _key: 'String:50+',
              accounting: { capacity: { milisatoshis: 'Integer:0..10' } },
              id: 'String:11..20',
              partners: [
                { node: {
                    _key: 'String:50+',
                    platform: { blockchain: 'String:0..10', network: 'String:0..10' },
                    public_key: 'String:50+'
                  },
                  state: 'Nil' },
                {
                  node: {
                    _key: 'String:50+',
                    platform: { blockchain: 'String:0..10', network: 'String:0..10' },
                    public_key: 'String:50+'
                  },
                  state: 'Nil'
                }
              ] }
          )
        end
      end
    end
  end
end
