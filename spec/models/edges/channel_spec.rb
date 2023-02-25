# frozen_string_literal: true

require 'json'

require_relative '../../../controllers/channel/mine'
require_relative '../../../controllers/channel/all'
require_relative '../../../controllers/channel/find_by_id'

require_relative '../../../models/edges/channel'

require_relative '../../../ports/dsl/lighstorm/errors'

RSpec.describe Lighstorm::Models::Channel do
  describe '.mine' do
    it 'models' do
      data = Lighstorm::Controllers::Channel::Mine.data do |fetch|
        VCR.replay('Controllers::Channel.mine') do
          data = fetch.call
          data[:list_channels] = [data[:list_channels][0].to_h]
          data
        end
      end

      channel = described_class.new(data[0])

      expect(channel._key.size).to eq(64)
      expect(channel.known?).to be(true)
      expect(channel.mine?).to be(true)

      expect(channel.id).to eq('850111604344029185')
      expect(channel.opened_at).to be_a(DateTime)
      expect(channel.opened_at.to_s.size).to eq(25)
      expect(channel.up_at).to be_a(DateTime)
      expect(channel.up_at).to be > channel.opened_at
      expect(channel.up_at.to_s.size).to eq(25)
      expect(channel.state).to be('active')
      expect(channel.active?).to be(true)
      expect(channel.exposure).to eq('public')

      expect(channel.transaction.funding.id.class).to eq(String)
      expect(channel.transaction.funding.id.size).to eq(66)
      expect(channel.transaction.funding.index.class).to eq(Integer)

      expect(channel.accounting.capacity.milisatoshis).to eq(6_200_000_000)
      expect(channel.accounting.capacity.satoshis).to eq(6_200_000)
      expect(channel.accounting.sent.milisatoshis).to eq(39_143_662_000)
      expect(channel.accounting.sent.satoshis).to eq(39_143_662)
      expect(channel.accounting.received.milisatoshis).to eq(33_041_910_000)
      expect(channel.accounting.received.satoshis).to eq(33_041_910)
      expect(channel.accounting.unsettled.milisatoshis).to eq(0)
      expect(channel.accounting.unsettled.satoshis).to eq(0)

      expect(channel.myself.node._key.size).to eq(64)
      expect(channel.myself.node.myself?).to be(true)
      expect(channel.myself.node.alias).to eq('icebaker/old-stone')
      expect(channel.myself.node.public_key).to eq('02d3c80335a8ccb2ed364c06875f32240f36f7edb37d80f8dbe321b4c364b6e997')
      expect(channel.myself.node.color).to eq('#ff338f')
      expect(channel.myself.accounting.balance.milisatoshis).to be > 10_000_000
      expect(channel.myself.accounting.balance.milisatoshis).to be < 200_000_000
      expect(channel.myself.accounting.balance.satoshis).to be > 10_000
      expect(channel.myself.accounting.balance.satoshis).to be < 200_000
      expect(channel.myself.policy.fee.base.milisatoshis).to eq(0)
      expect(channel.myself.policy.fee.base.satoshis).to eq(0)
      expect(channel.myself.policy.fee.rate.parts_per_million).to eq(94)
      expect(channel.myself.policy.fee.rate.percentage).to eq(0.0094)
      expect(channel.myself.policy.htlc.minimum.milisatoshis).to eq(1000)
      expect(channel.myself.policy.htlc.minimum.satoshis).to eq(1)
      expect(channel.myself.policy.htlc.maximum.milisatoshis).to eq(6_045_000_000)
      expect(channel.myself.policy.htlc.maximum.satoshis).to eq(6_045_000)

      expect(channel.myself.policy.htlc.blocks.delta.minimum).to eq(40)

      expect(channel.myself.node.platform.blockchain).to eq('bitcoin')
      expect(channel.myself.node.platform.network).to eq('mainnet')
      expect(channel.myself.node.platform.lightning.implementation).to eq('lnd')
      expect(channel.myself.node.platform.lightning.version).to eq('0.15.5-beta commit=v0.15.5-beta')

      expect(channel.partners[0].node._key.size).to eq(64)
      expect(channel.partners[0].node.myself?).to be(true)
      expect(channel.partners[0].node.alias).to eq('icebaker/old-stone')
      expect(channel.partners[0].node.public_key).to eq('02d3c80335a8ccb2ed364c06875f32240f36f7edb37d80f8dbe321b4c364b6e997')
      expect(channel.partners[0].node.color).to eq('#ff338f')
      expect(channel.partners[0].accounting.balance.milisatoshis).to be > 10_000_000
      expect(channel.partners[0].accounting.balance.milisatoshis).to be < 200_000_000
      expect(channel.partners[0].accounting.balance.satoshis).to be > 10_000
      expect(channel.partners[0].accounting.balance.satoshis).to be < 200_000
      expect(channel.partners[0].policy.fee.base.milisatoshis).to eq(0)
      expect(channel.partners[0].policy.fee.base.satoshis).to eq(0)
      expect(channel.partners[0].policy.fee.rate.parts_per_million).to eq(94)
      expect(channel.partners[0].policy.fee.rate.percentage).to eq(0.0094)
      expect(channel.partners[0].policy.htlc.minimum.milisatoshis).to eq(1000)
      expect(channel.partners[0].policy.htlc.minimum.satoshis).to eq(1)
      expect(channel.partners[0].policy.htlc.maximum.milisatoshis).to eq(6_045_000_000)
      expect(channel.partners[0].policy.htlc.maximum.satoshis).to eq(6_045_000)
      expect(channel.partners[0].node.platform.blockchain).to eq('bitcoin')
      expect(channel.partners[0].node.platform.network).to eq('mainnet')
      expect(channel.partners[0].node.platform.lightning.implementation).to eq('lnd')
      expect(channel.partners[0].node.platform.lightning.version).to eq('0.15.5-beta commit=v0.15.5-beta')

      expect(channel.partner.node._key.size).to eq(64)
      expect(channel.partner.node.myself?).to be(false)
      expect(channel.partner.node.alias).to eq('deezy.io ⚡✨')
      expect(channel.partner.node.public_key).to eq('024bfaf0cabe7f874fd33ebf7c6f4e5385971fc504ef3f492432e9e3ec77e1b5cf')
      expect(channel.partner.node.color).to eq('#3399ff')
      expect(channel.partner.accounting.balance.milisatoshis).to eq(6_101_752_000)
      expect(channel.partner.accounting.balance.satoshis).to eq(6_101_752)
      expect(channel.partner.policy.fee.base.milisatoshis).to eq(0)
      expect(channel.partner.policy.fee.base.satoshis).to eq(0)
      expect(channel.partner.policy.fee.rate.parts_per_million).to eq(0)
      expect(channel.partner.policy.fee.rate.percentage).to eq(0.0)
      expect(channel.partner.policy.htlc.minimum.milisatoshis).to eq(1000)
      expect(channel.partner.policy.htlc.minimum.satoshis).to eq(1)
      expect(channel.partner.policy.htlc.maximum.milisatoshis).to be > 5_000_000_000
      expect(channel.partner.policy.htlc.maximum.milisatoshis).to be < 7_000_000_000
      expect(channel.partner.policy.htlc.maximum.satoshis).to be > 5_000_00
      expect(channel.partner.policy.htlc.maximum.satoshis).to be < 7_000_000
      expect(channel.partner.node.platform.blockchain).to eq('bitcoin')
      expect(channel.partner.node.platform.network).to eq('mainnet')

      expect { channel.partner.node.platform.lightning }.to raise_error(
        NotYourNodeError
      )

      expect(channel.partners[1].node._key.size).to eq(64)
      expect(channel.partners[1].node.myself?).to be(false)
      expect(channel.partners[1].node.alias).to eq('deezy.io ⚡✨')
      expect(channel.partners[1].node.public_key).to eq('024bfaf0cabe7f874fd33ebf7c6f4e5385971fc504ef3f492432e9e3ec77e1b5cf')
      expect(channel.partners[1].node.color).to eq('#3399ff')
      expect(channel.partners[1].accounting.balance.milisatoshis).to eq(6_101_752_000)
      expect(channel.partners[1].accounting.balance.satoshis).to eq(6_101_752)
      expect(channel.partners[1].policy.fee.base.milisatoshis).to eq(0)
      expect(channel.partners[1].policy.fee.base.satoshis).to eq(0)
      expect(channel.partners[1].policy.fee.rate.parts_per_million).to eq(0)
      expect(channel.partners[1].policy.fee.rate.percentage).to eq(0.0)
      expect(channel.partners[1].policy.htlc.minimum.milisatoshis).to eq(1000)
      expect(channel.partners[1].policy.htlc.minimum.satoshis).to eq(1)
      expect(channel.partners[1].policy.htlc.maximum.milisatoshis).to be > 5_000_000_000
      expect(channel.partners[1].policy.htlc.maximum.milisatoshis).to be < 7_000_000_000
      expect(channel.partners[1].policy.htlc.maximum.satoshis).to be > 5_000_000
      expect(channel.partners[1].policy.htlc.maximum.satoshis).to be < 7_000_000
      expect(channel.partners[1].node.platform.blockchain).to eq('bitcoin')
      expect(channel.partners[1].node.platform.network).to eq('mainnet')

      expect { channel.partners[1].node.platform.lightning }.to raise_error(
        NotYourNodeError
      )

      Contract.expect(
        channel.to_h, '727cfffebcc4a3cb627aa8b3eacb04c932215caf217220873887e502bdfd38cf'
      ) do |actual, expected|
        expect(actual.hash).to eq(expected.hash)
        expect(actual.contract).to eq(expected.contract)
      end
    end
  end

  describe '.find_by_id' do
    context 'mine' do
      it 'models' do
        channel_id = '850111604344029185'

        data = Lighstorm::Controllers::Channel::FindById.data(channel_id) do |fetch|
          VCR.replay("Controllers::Channel.find_by_id/#{channel_id}") { fetch.call }
        end

        channel = described_class.new(data)

        as_hash = channel.to_h

        expect(channel._key.size).to eq(64)
        expect(channel.known?).to be(true)
        expect(channel.mine?).to be(true)

        expect(channel.id).to eq(channel_id)
        expect(channel.opened_at).to be_a(DateTime)
        expect(channel.opened_at.to_s.size).to eq(25)
        expect(channel.up_at).to be_a(DateTime)
        expect(channel.up_at.to_s.size).to eq(25)
        expect(channel.state).to be('active')
        expect(channel.active?).to be(true)
        expect(channel.exposure).to eq('public')

        expect(channel.accounting.capacity.milisatoshis).to eq(6_200_000_000)
        expect(channel.accounting.capacity.satoshis).to eq(6_200_000)
        expect(channel.accounting.sent.milisatoshis).to eq(39_143_662_000)
        expect(channel.accounting.sent.satoshis).to eq(39_143_662)
        expect(channel.accounting.received.milisatoshis).to eq(33_041_910_000)
        expect(channel.accounting.received.satoshis).to eq(33_041_910)
        expect(channel.accounting.unsettled.milisatoshis).to eq(0)
        expect(channel.accounting.unsettled.satoshis).to eq(0)

        expect(channel.myself.node._key.size).to eq(64)
        expect(channel.myself.node.myself?).to be(true)
        expect(channel.myself.node.alias).to eq('icebaker/old-stone')
        expect(channel.myself.node.public_key).to eq('02d3c80335a8ccb2ed364c06875f32240f36f7edb37d80f8dbe321b4c364b6e997')
        expect(channel.myself.node.color).to eq('#ff338f')
        expect(channel.myself.accounting.balance.milisatoshis).to be > 10_000_000
        expect(channel.myself.accounting.balance.milisatoshis).to be < 200_000_000
        expect(channel.myself.accounting.balance.satoshis).to be > 10_000
        expect(channel.myself.accounting.balance.satoshis).to be < 200_000
        expect(channel.myself.policy.fee.base.milisatoshis).to eq(0)
        expect(channel.myself.policy.fee.base.satoshis).to eq(0)
        expect(channel.myself.policy.fee.rate.parts_per_million).to eq(94)
        expect(channel.myself.policy.fee.rate.percentage).to eq(0.0094)
        expect(channel.myself.policy.htlc.minimum.milisatoshis).to eq(1000)
        expect(channel.myself.policy.htlc.minimum.satoshis).to eq(1)
        expect(channel.myself.policy.htlc.maximum.milisatoshis).to eq(6_045_000_000)
        expect(channel.myself.policy.htlc.maximum.satoshis).to eq(6_045_000)
        expect(channel.myself.node.platform.blockchain).to eq('bitcoin')
        expect(channel.myself.node.platform.network).to eq('mainnet')
        expect(channel.myself.node.platform.lightning.implementation).to eq('lnd')
        expect(channel.myself.node.platform.lightning.version).to eq('0.15.5-beta commit=v0.15.5-beta')

        expect(channel.partners[1].node._key.size).to eq(64)
        expect(channel.partners[1].node.myself?).to be(true)
        expect(channel.partners[1].node.alias).to eq('icebaker/old-stone')
        expect(channel.partners[1].node.public_key).to eq('02d3c80335a8ccb2ed364c06875f32240f36f7edb37d80f8dbe321b4c364b6e997')
        expect(channel.partners[1].node.color).to eq('#ff338f')
        expect(channel.partners[1].accounting.balance.milisatoshis).to be > 10_000_000
        expect(channel.partners[1].accounting.balance.milisatoshis).to be < 200_000_000
        expect(channel.partners[1].accounting.balance.satoshis).to be > 10_000
        expect(channel.partners[1].accounting.balance.satoshis).to be < 200_000
        expect(channel.partners[1].policy.fee.base.milisatoshis).to eq(0)
        expect(channel.partners[1].policy.fee.base.satoshis).to eq(0)
        expect(channel.partners[1].policy.fee.rate.parts_per_million).to eq(94)
        expect(channel.partners[1].policy.fee.rate.percentage).to eq(0.0094)
        expect(channel.partners[1].policy.htlc.minimum.milisatoshis).to eq(1000)
        expect(channel.partners[1].policy.htlc.minimum.satoshis).to eq(1)
        expect(channel.partners[1].policy.htlc.maximum.milisatoshis).to eq(6_045_000_000)
        expect(channel.partners[1].policy.htlc.maximum.satoshis).to eq(6_045_000)
        expect(channel.partners[1].node.platform.blockchain).to eq('bitcoin')
        expect(channel.partners[1].node.platform.network).to eq('mainnet')
        expect(channel.partners[1].node.platform.lightning.implementation).to eq('lnd')
        expect(channel.partners[1].node.platform.lightning.version).to eq('0.15.5-beta commit=v0.15.5-beta')

        expect(channel.partner.node._key.size).to eq(64)
        expect(channel.partner.node.myself?).to be(false)
        expect(channel.partner.node.alias).to eq('deezy.io ⚡✨')
        expect(channel.partner.node.public_key).to eq('024bfaf0cabe7f874fd33ebf7c6f4e5385971fc504ef3f492432e9e3ec77e1b5cf')
        expect(channel.partner.node.color).to eq('#3399ff')
        expect(channel.partner.accounting.balance.milisatoshis).to eq(6_101_752_000)
        expect(channel.partner.accounting.balance.satoshis).to eq(6_101_752)
        expect(channel.partner.policy.fee.base.milisatoshis).to eq(0)
        expect(channel.partner.policy.fee.base.satoshis).to eq(0)
        expect(channel.partner.policy.fee.rate.parts_per_million).to eq(0)
        expect(channel.partner.policy.fee.rate.percentage).to eq(0.0)
        expect(channel.partner.policy.htlc.minimum.milisatoshis).to eq(1000)
        expect(channel.partner.policy.htlc.minimum.satoshis).to eq(1)
        expect(channel.partner.policy.htlc.maximum.milisatoshis).to be > 5_000_000_000
        expect(channel.partner.policy.htlc.maximum.milisatoshis).to be < 7_000_000_000
        expect(channel.partner.policy.htlc.maximum.satoshis).to be > 5_000_000
        expect(channel.partner.policy.htlc.maximum.satoshis).to be < 7_000_000
        expect(channel.partner.node.platform.blockchain).to eq('bitcoin')
        expect(channel.partner.node.platform.network).to eq('mainnet')

        expect { channel.partner.node.platform.lightning }.to raise_error(
          NotYourNodeError
        )

        expect(channel.partners[0].node._key.size).to eq(64)
        expect(channel.partners[0].node.myself?).to be(false)
        expect(channel.partners[0].node.alias).to eq('deezy.io ⚡✨')
        expect(channel.partners[0].node.public_key).to eq('024bfaf0cabe7f874fd33ebf7c6f4e5385971fc504ef3f492432e9e3ec77e1b5cf')
        expect(channel.partners[0].node.color).to eq('#3399ff')
        expect(channel.partners[0].accounting.balance.milisatoshis).to eq(6_101_752_000)
        expect(channel.partners[0].accounting.balance.satoshis).to eq(6_101_752)
        expect(channel.partners[0].policy.fee.base.milisatoshis).to eq(0)
        expect(channel.partners[0].policy.fee.base.satoshis).to eq(0)
        expect(channel.partners[0].policy.fee.rate.parts_per_million).to eq(0)
        expect(channel.partners[0].policy.fee.rate.percentage).to eq(0.0)
        expect(channel.partners[0].policy.htlc.minimum.milisatoshis).to eq(1000)
        expect(channel.partners[0].policy.htlc.minimum.satoshis).to eq(1)
        expect(channel.partners[0].policy.htlc.maximum.milisatoshis).to be > 5_000_000_000
        expect(channel.partners[0].policy.htlc.maximum.milisatoshis).to be < 7_000_000_000
        expect(channel.partners[0].policy.htlc.maximum.satoshis).to be > 5_000_000
        expect(channel.partners[0].policy.htlc.maximum.satoshis).to be < 7_000_000
        expect(channel.partners[0].node.platform.blockchain).to eq('bitcoin')
        expect(channel.partners[0].node.platform.network).to eq('mainnet')

        expect { channel.partners[0].node.platform.lightning }.to raise_error(
          NotYourNodeError
        )

        Contract.expect(
          channel.to_h, '727cfffebcc4a3cb627aa8b3eacb04c932215caf217220873887e502bdfd38cf'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)
        end
      end
    end

    context 'other' do
      it 'models' do
        channel_id = '553951550347608065'

        data = Lighstorm::Controllers::Channel::FindById.data(channel_id) do |fetch|
          VCR.replay("Controllers::Channel.find_by_id/#{channel_id}") { fetch.call }
        end

        channel = described_class.new(data)

        expect(channel._key.size).to eq(64)
        expect(channel.known?).to be(true)
        expect(channel.mine?).to be(false)

        expect(channel.id).to eq(channel_id)

        expect { channel.opened_at }.to raise_error(NotYourChannelError)
        expect { channel.up_at }.to raise_error(NotYourChannelError)
        expect { channel.state }.to raise_error(NotYourChannelError)
        expect { channel.active? }.to raise_error(NotYourChannelError)

        expect(channel.exposure).to eq('public')

        expect(channel.accounting.capacity.milisatoshis).to eq(37_200_000)
        expect(channel.accounting.capacity.satoshis).to eq(37_200)

        expect { channel.accounting.sent }.to raise_error(NotYourChannelError)
        expect { channel.accounting.received }.to raise_error(NotYourChannelError)
        expect { channel.accounting.unsettled }.to raise_error(NotYourChannelError)

        expect { channel.myself }.to raise_error(NotYourChannelError)

        expect(channel.partners[0].node._key.size).to eq(64)
        expect(channel.partners[0].node.myself?).to be(false)
        expect(channel.partners[0].node.alias).to eq('')
        expect(channel.partners[0].node.public_key).to eq('03bd3466efd4a7306b539e2314e69efc6b1eaee29734fcedd78cf81b1dde9fedf8')
        expect(channel.partners[0].node.color).to eq('#000000')

        expect { channel.partners[0].accounting }.to raise_error(NotYourChannelError)

        expect(channel.partners[0].policy.fee.base).to be_nil
        expect(channel.partners[0].policy.fee.rate).to be_nil
        expect(channel.partners[0].policy.htlc.minimum).to be_nil
        expect(channel.partners[0].policy.htlc.maximum).to be_nil
        expect(channel.partners[0].policy.htlc.blocks.delta.minimum).to be_nil
        expect(channel.partners[0].node.platform.blockchain).to eq('bitcoin')
        expect(channel.partners[0].node.platform.network).to eq('mainnet')

        expect { channel.partners[0].node.platform.lightning }.to raise_error(NotYourNodeError)

        expect { channel.partner }.to raise_error(NotYourChannelError)

        expect(channel.partners[1].node._key.size).to eq(64)
        expect(channel.partners[1].node.myself?).to be(false)
        expect(channel.partners[1].node.alias).to eq('')
        expect(channel.partners[1].node.public_key).to eq('03c3d14714b78f03fd6ea4997c2b540a4139258249ea1d625c03b68bb82f85d0ea')
        expect(channel.partners[1].node.color).to eq('#000000')

        expect { channel.partners[1].accounting }.to raise_error(NotYourChannelError)

        expect(channel.partners[1].policy.fee.base).to be_nil
        expect(channel.partners[1].policy.fee.rate).to be_nil
        expect(channel.partners[1].policy.htlc.minimum).to be_nil
        expect(channel.partners[1].policy.htlc.maximum).to be_nil
        expect(channel.partners[1].policy.htlc.blocks.delta.minimum).to be_nil

        expect(channel.partners[1].node.platform.blockchain).to eq('bitcoin')
        expect(channel.partners[1].node.platform.network).to eq('mainnet')

        expect { channel.partners[1].node.platform.lightning }.to raise_error(NotYourNodeError)

        Contract.expect(
          channel.to_h, '05f7283abe9bbb861f4e0c56aa0d45bd49ee3164123412f375d115c833327d70'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)
        end
      end
    end

    context 'popular' do
      it 'models' do
        channel_id = '853996178921881601'

        data = Lighstorm::Controllers::Channel::FindById.data(channel_id) do |fetch|
          VCR.replay("Controllers::Channel.find_by_id/#{channel_id}") { fetch.call }
        end

        channel = described_class.new(data)

        expect(channel._key.size).to eq(64)
        expect(channel.known?).to be(true)
        expect(channel.mine?).to be(false)

        expect(channel.id).to eq(channel_id)

        expect { channel.opened_at }.to raise_error(NotYourChannelError)
        expect { channel.up_at }.to raise_error(NotYourChannelError)
        expect { channel.state }.to raise_error(NotYourChannelError)
        expect { channel.active? }.to raise_error(NotYourChannelError)

        expect(channel.exposure).to eq('public')

        expect(channel.accounting.capacity.milisatoshis).to eq(200_000_000_000)
        expect(channel.accounting.capacity.satoshis).to eq(200_000_000)
        expect(channel.accounting.capacity.bitcoins).to eq(2)

        expect { channel.accounting.sent }.to raise_error(NotYourChannelError)
        expect { channel.accounting.received }.to raise_error(NotYourChannelError)
        expect { channel.accounting.unsettled }.to raise_error(NotYourChannelError)

        expect { channel.myself }.to raise_error(NotYourChannelError)

        expect(channel.partners[0].node._key.size).to eq(64)
        expect(channel.partners[0].node.myself?).to be(false)
        expect(channel.partners[0].node.alias).to eq('deezy.io ⚡✨')
        expect(channel.partners[0].node.public_key).to eq('024bfaf0cabe7f874fd33ebf7c6f4e5385971fc504ef3f492432e9e3ec77e1b5cf')
        expect(channel.partners[0].node.color).to eq('#3399ff')

        expect { channel.partners[0].accounting }.to raise_error(NotYourChannelError)

        expect(channel.partners[0].policy.fee.base.milisatoshis).to eq(0)
        expect(channel.partners[0].policy.fee.base.satoshis).to eq(0)
        expect(channel.partners[0].policy.fee.rate.parts_per_million).to eq(0)
        expect(channel.partners[0].policy.fee.rate.percentage).to eq(0.0)
        expect(channel.partners[0].policy.htlc.minimum.milisatoshis).to eq(1000)
        expect(channel.partners[0].policy.htlc.minimum.satoshis).to eq(1)
        expect(channel.partners[0].policy.htlc.maximum.milisatoshis).to be > 1_000_000_000
        expect(channel.partners[0].policy.htlc.maximum.milisatoshis).to be < 500_000_000_000
        expect(channel.partners[0].policy.htlc.maximum.satoshis).to be >   1_000_000
        expect(channel.partners[0].policy.htlc.maximum.satoshis).to be < 500_000_000
        expect(channel.partners[0].node.platform.blockchain).to eq('bitcoin')
        expect(channel.partners[0].node.platform.network).to eq('mainnet')

        expect { channel.partners[0].node.platform.lightning }.to raise_error(
          NotYourNodeError
        )

        expect { channel.partner }.to raise_error(NotYourChannelError)

        expect(channel.partners[1].node._key.size).to eq(64)
        expect(channel.partners[1].node.myself?).to be(false)
        expect(channel.partners[1].node.alias).to eq('cyberdyne.sh')
        expect(channel.partners[1].node.public_key).to eq('03a93b87bf9f052b8e862d51ebbac4ce5e97b5f4137563cd5128548d7f5978dda9')
        expect(channel.partners[1].node.color).to eq('#03fc88')

        expect { channel.partners[1].accounting }.to raise_error(NotYourChannelError)

        expect(channel.partners[1].policy.fee.base.milisatoshis).to eq(0)
        expect(channel.partners[1].policy.fee.base.satoshis).to eq(0)
        expect(channel.partners[1].policy.fee.rate.parts_per_million).to be > 0
        expect(channel.partners[1].policy.fee.rate.parts_per_million).to be < 500
        expect(channel.partners[1].policy.fee.rate.percentage).to be > 0.0
        expect(channel.partners[1].policy.fee.rate.percentage).to be < 0.0500
        expect(channel.partners[1].policy.htlc.minimum.milisatoshis).to eq(1000)
        expect(channel.partners[1].policy.htlc.minimum.satoshis).to eq(1)
        expect(channel.partners[1].policy.htlc.maximum.milisatoshis).to be > 1_000_000_000
        expect(channel.partners[1].policy.htlc.maximum.milisatoshis).to be < 500_000_000_000
        expect(channel.partners[1].policy.htlc.maximum.satoshis).to be >   1_000_000
        expect(channel.partners[1].policy.htlc.maximum.satoshis).to be < 500_000_000
        expect(channel.partners[1].node.platform.blockchain).to eq('bitcoin')
        expect(channel.partners[1].node.platform.network).to eq('mainnet')

        expect { channel.partners[1].node.platform.lightning }.to raise_error(NotYourNodeError)

        Contract.expect(
          channel.to_h, '168edbce05294fb68511b986c7b0da7f85045928b426c3731d18011455e76b90'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)
        end
      end
    end
  end

  describe 'all' do
    let :data do
      Lighstorm::Controllers::Channel::All.data do |fetch|
        VCR.replay('Controllers::Channel.all') do
          data = fetch.call

          mine = Lighstorm::Controllers::Channel::Mine.data.map { |c| c[:id] }

          data[:describe_graph] = [
            data[:describe_graph].find { |n| !mine.include?(n.channel_id.to_s) },
            data[:describe_graph].find { |n| mine.include?(n.channel_id.to_s) }
          ].map(&:to_h)

          data
        end
      end
    end

    context 'other' do
      it 'models' do
        channel = described_class.new(data[0])

        expect(channel._key.size).to eq(64)
        expect(channel.known?).to be(true)
        expect(channel.mine?).to be(false)

        expect(channel.id).to eq('553951550347608065')

        expect { channel.opened_at }.to raise_error(NotYourChannelError)
        expect { channel.up_at }.to raise_error(NotYourChannelError)
        expect { channel.state }.to raise_error(NotYourChannelError)
        expect { channel.active? }.to raise_error(NotYourChannelError)

        expect(channel.exposure).to eq('public')

        expect(channel.accounting.capacity.milisatoshis).to eq(37_200_000)
        expect(channel.accounting.capacity.satoshis).to eq(37_200)

        expect { channel.accounting.sent }.to raise_error(NotYourChannelError)
        expect { channel.accounting.received }.to raise_error(NotYourChannelError)
        expect { channel.accounting.unsettled }.to raise_error(NotYourChannelError)

        expect { channel.myself }.to raise_error(NotYourChannelError)

        expect(channel.partners[0].node._key.size).to eq(64)
        expect(channel.partners[0].node.alias).to be_nil
        expect(channel.partners[0].node.public_key).to eq('03bd3466efd4a7306b539e2314e69efc6b1eaee29734fcedd78cf81b1dde9fedf8')
        expect(channel.partners[0].node.color).to be_nil

        expect { channel.partners[0].accounting }.to raise_error(NotYourChannelError)

        expect(channel.partners[0].policy.fee.base).to be_nil
        expect(channel.partners[0].policy.fee.rate).to be_nil
        expect(channel.partners[0].policy.htlc.minimum).to be_nil
        expect(channel.partners[0].policy.htlc.maximum).to be_nil
        expect(channel.partners[0].policy.htlc.blocks.delta.minimum).to be_nil

        expect(channel.partners[0].node.platform.blockchain).to eq('bitcoin')
        expect(channel.partners[0].node.platform.network).to eq('mainnet')

        expect { channel.partners[0].node.platform.lightning }.to raise_error(NotYourNodeError)

        expect { channel.partner }.to raise_error(NotYourChannelError)

        expect { channel.partner.node.platform.lightning }.to raise_error(
          NotYourChannelError
        )

        expect(channel.partners[1].node._key.size).to eq(64)
        expect(channel.partners[1].node.alias).to be_nil
        expect(channel.partners[1].node.public_key).to eq('03c3d14714b78f03fd6ea4997c2b540a4139258249ea1d625c03b68bb82f85d0ea')
        expect(channel.partners[1].node.color).to be_nil

        expect { channel.partners[1].accounting }.to raise_error(NotYourChannelError)

        expect(channel.partners[1].policy.fee.base).to be_nil
        expect(channel.partners[1].policy.fee.rate).to be_nil
        expect(channel.partners[1].policy.htlc.minimum).to be_nil
        expect(channel.partners[1].policy.htlc.maximum).to be_nil
        expect(channel.partners[1].policy.htlc.blocks.delta.minimum).to be_nil

        expect(channel.partners[1].node.platform.blockchain).to eq('bitcoin')
        expect(channel.partners[1].node.platform.network).to eq('mainnet')

        expect { channel.partners[1].node.platform.lightning }.to raise_error(NotYourNodeError)

        Contract.expect(
          channel.to_h, 'db4d187e10fdf9461f0a6818ec78787f0bd9f5675e344ad785ff1293eac3e8e3'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)
        end
      end
    end

    context 'mine' do
      it 'models' do
        channel = described_class.new(data[1])

        expect(channel._key.size).to eq(64)
        expect(channel.known?).to be(true)
        expect(channel.mine?).to be(true)

        expect(channel.id).to eq('848916435345801217')

        expect(channel.opened_at).to be_a(DateTime)
        expect(channel.opened_at.to_s.size).to eq(25)
        expect(channel.up_at).to be_a(DateTime)
        expect(channel.up_at.to_s.size).to eq(25)
        expect(channel.state).to eq('active')
        expect(channel.active?).to be(true)
        expect(channel.exposure).to eq('public')

        expect(channel.accounting.capacity.milisatoshis).to eq(6_500_000_000)
        expect(channel.accounting.capacity.satoshis).to eq(6_500_000)
        expect(channel.accounting.sent.milisatoshis).to eq(7_710_146_000)
        expect(channel.accounting.sent.satoshis).to eq(7_710_146)
        expect(channel.accounting.received.milisatoshis).to eq(2_278_505_000)
        expect(channel.accounting.received.satoshis).to eq(2_278_505)
        expect(channel.accounting.unsettled.milisatoshis).to eq(0)
        expect(channel.accounting.unsettled.satoshis).to eq(0)

        expect(channel.myself.node._key.size).to eq(64)
        expect(channel.myself.node.alias).to eq('icebaker/old-stone')
        expect(channel.myself.node.public_key).to eq('02d3c80335a8ccb2ed364c06875f32240f36f7edb37d80f8dbe321b4c364b6e997')
        expect(channel.myself.node.color).to eq('#ff338f')
        expect(channel.myself.accounting.balance.milisatoshis).to be > 500_000_000
        expect(channel.myself.accounting.balance.milisatoshis).to be < 10_000_000_000
        expect(channel.myself.accounting.balance.satoshis).to be > 500_000
        expect(channel.myself.accounting.balance.satoshis).to be < 10_000_000
        expect(channel.myself.policy.fee.base.milisatoshis).to eq(0)
        expect(channel.myself.policy.fee.base.satoshis).to eq(0)
        expect(channel.myself.policy.fee.rate.parts_per_million).to eq(874)
        expect(channel.myself.policy.fee.rate.percentage).to eq(0.0874)
        expect(channel.myself.policy.htlc.minimum.milisatoshis).to eq(1000)
        expect(channel.myself.policy.htlc.minimum.satoshis).to eq(1)
        expect(channel.myself.policy.htlc.maximum.milisatoshis).to eq(6_045_000_000)
        expect(channel.myself.policy.htlc.maximum.satoshis).to eq(6_045_000)
        expect(channel.myself.node.platform.blockchain).to eq('bitcoin')
        expect(channel.myself.node.platform.network).to eq('mainnet')
        expect(channel.myself.node.platform.lightning.implementation).to eq('lnd')
        expect(channel.myself.node.platform.lightning.version).to eq('0.15.5-beta commit=v0.15.5-beta')

        expect(channel.partners[0].node._key.size).to eq(64)
        expect(channel.partners[0].node.alias).to eq('icebaker/old-stone')
        expect(channel.partners[0].node.public_key).to eq('02d3c80335a8ccb2ed364c06875f32240f36f7edb37d80f8dbe321b4c364b6e997')
        expect(channel.partners[0].node.color).to eq('#ff338f')
        expect(channel.partners[0].accounting.balance.milisatoshis).to be > 500_000_000
        expect(channel.partners[0].accounting.balance.milisatoshis).to be < 10_000_000_000
        expect(channel.partners[0].accounting.balance.satoshis).to be > 500_000
        expect(channel.partners[0].accounting.balance.satoshis).to be < 10_000_000
        expect(channel.partners[0].policy.fee.base.milisatoshis).to eq(0)
        expect(channel.partners[0].policy.fee.base.satoshis).to eq(0)
        expect(channel.partners[0].policy.fee.rate.parts_per_million).to eq(874)
        expect(channel.partners[0].policy.fee.rate.percentage).to eq(0.0874)
        expect(channel.partners[0].policy.htlc.minimum.milisatoshis).to eq(1000)
        expect(channel.partners[0].policy.htlc.minimum.satoshis).to eq(1)
        expect(channel.partners[0].policy.htlc.maximum.milisatoshis).to eq(6_045_000_000)
        expect(channel.partners[0].policy.htlc.maximum.satoshis).to eq(6_045_000)
        expect(channel.partners[0].node.platform.blockchain).to eq('bitcoin')
        expect(channel.partners[0].node.platform.network).to eq('mainnet')
        expect(channel.partners[0].node.platform.lightning.implementation).to eq('lnd')
        expect(channel.partners[0].node.platform.lightning.version).to eq('0.15.5-beta commit=v0.15.5-beta')

        expect(channel.partner.node._key.size).to eq(64)
        expect(channel.partner.node.alias).to eq('WalletOfSatoshi.com')
        expect(channel.partner.node.public_key).to eq('035e4ff418fc8b5554c5d9eea66396c227bd429a3251c8cbc711002ba215bfc226')
        expect(channel.partner.node.color).to eq('#3399ff')
        expect(channel.partner.accounting.balance.milisatoshis).to eq(5_431_641_000)
        expect(channel.partner.accounting.balance.satoshis).to eq(5_431_641)
        expect(channel.partner.policy.fee.base.milisatoshis).to eq(0)
        expect(channel.partner.policy.fee.base.satoshis).to eq(0)
        expect(channel.partner.policy.fee.rate.parts_per_million).to eq(300)
        expect(channel.partner.policy.fee.rate.percentage).to eq(0.03)
        expect(channel.partner.policy.htlc.minimum.milisatoshis).to eq(1000)
        expect(channel.partner.policy.htlc.minimum.satoshis).to eq(1)
        expect(channel.partner.policy.htlc.maximum.milisatoshis).to eq(6_435_000_000)
        expect(channel.partner.policy.htlc.maximum.satoshis).to eq(6_435_000)
        expect(channel.partner.node.platform.blockchain).to eq('bitcoin')
        expect(channel.partner.node.platform.network).to eq('mainnet')

        expect { channel.partner.node.platform.lightning }.to raise_error(NotYourNodeError)

        expect(channel.partners[1].node._key.size).to eq(64)
        expect(channel.partners[1].node.alias).to eq('WalletOfSatoshi.com')
        expect(channel.partners[1].node.public_key).to eq('035e4ff418fc8b5554c5d9eea66396c227bd429a3251c8cbc711002ba215bfc226')
        expect(channel.partners[1].node.color).to eq('#3399ff')
        expect(channel.partners[1].accounting.balance.milisatoshis).to eq(5_431_641_000)
        expect(channel.partners[1].accounting.balance.satoshis).to eq(5_431_641)
        expect(channel.partners[1].policy.fee.base.milisatoshis).to eq(0)
        expect(channel.partners[1].policy.fee.base.satoshis).to eq(0)
        expect(channel.partners[1].policy.fee.rate.parts_per_million).to eq(300)
        expect(channel.partners[1].policy.fee.rate.percentage).to eq(0.03)
        expect(channel.partners[1].policy.htlc.minimum.milisatoshis).to eq(1000)
        expect(channel.partners[1].policy.htlc.minimum.satoshis).to eq(1)
        expect(channel.partners[1].policy.htlc.maximum.milisatoshis).to eq(6_435_000_000)
        expect(channel.partners[1].policy.htlc.maximum.satoshis).to eq(6_435_000)
        expect(channel.partners[1].node.platform.blockchain).to eq('bitcoin')
        expect(channel.partners[1].node.platform.network).to eq('mainnet')

        expect { channel.partners[1].node.platform.lightning }.to raise_error(NotYourNodeError)

        Contract.expect(
          channel.to_h, '21df298a1220ec2d5dbeeb545d02b7676a8bb0fb9f7d2312dcf620b11cb808dc'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)
        end
      end
    end
  end
end
