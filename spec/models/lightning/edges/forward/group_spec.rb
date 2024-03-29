# frozen_string_literal: true

require 'json'

# Circular dependency issue:
# https://stackoverflow.com/questions/8057625/ruby-how-to-require-correctly-to-avoid-circular-dependencies
require_relative '../../../../../models/lightning/edges/channel/hop'
require_relative '../../../../../controllers/lightning/forward'
require_relative '../../../../../controllers/lightning/forward/group_by_channel'

require_relative '../../../../../models/lightning/edges/groups/channel_forwards'

require_relative '../../../../../ports/dsl/lighstorm/errors'

RSpec.describe Lighstorm::Model::Lightning::ChannelForwardsGroup do
  describe 'all' do
    context 'no filters' do
      let(:data) do
        data = Lighstorm::Controller::Lightning::Forward::GroupByChannel.data(
          Lighstorm::Controller::Lightning::Forward.components
        ) do |fetch|
          VCR.tape.replay('Controller::Lightning::Forward.group_by_channel') { fetch.call }
        end
      end

      context 'known peer' do
        it 'models' do
          group = described_class.new(
            data.find { |d| d[:channel][:known] },
            Lighstorm::Controller::Lightning::Forward.components
          )

          expect(group._key.size).to eq(64)

          expect(group.last_at).to be_a(Time)
          expect(group.last_at.utc.to_s).to eq('2023-03-25 10:59:24 UTC')

          # ------------------------------------------------------------------

          expect(group.analysis.count).to eq(320)

          expect(group.analysis.sums.amount.millisatoshis).to eq(32_205_780_767)
          expect(group.analysis.sums.amount.satoshis).to eq(32_205_780.767)
          expect(group.analysis.sums.fee.millisatoshis).to eq(2_399_303)
          expect(group.analysis.sums.fee.satoshis).to eq(2399.303)

          expect(group.analysis.averages.amount.millisatoshis).to eq(100_643_064.896875)
          expect(group.analysis.averages.amount.satoshis).to eq(100_643.06489687499)
          expect(group.analysis.averages.fee.millisatoshis).to eq(7497.821875)
          expect(group.analysis.averages.fee.satoshis).to eq(7.497821875)

          # ------------------------------------------------------------------

          expect(group.channel._key.size).to eq(64)
          expect(group.channel.known?).to be(true)
          expect(group.channel.mine?).to be(true)

          expect(group.channel.id).to eq('850111604344029185')
          expect(group.channel.opened_at).to be_a(Time)
          expect(group.channel.opened_at.utc.to_s.size).to eq(23)
          expect(group.channel.up_at).to be_a(Time)
          expect(group.channel.up_at.utc.to_s.size).to eq(23)
          expect(group.channel.up_at).to be > group.channel.opened_at
          expect(group.channel.state).to be('active')
          expect(group.channel.active?).to be(true)
          expect(group.channel.exposure).to eq('public')

          expect(group.channel.accounting.capacity.millisatoshis).to eq(6_200_000_000)
          expect(group.channel.accounting.capacity.satoshis).to eq(6_200_000)
          expect(group.channel.accounting.sent.millisatoshis).to eq(39_674_083_000)
          expect(group.channel.accounting.sent.satoshis).to eq(39_674_083.0)
          expect(group.channel.accounting.received.millisatoshis).to be > 30_000_000_000
          expect(group.channel.accounting.received.millisatoshis).to be < 100_000_000_000
          expect(group.channel.accounting.received.satoshis).to be > 30_000_000
          expect(group.channel.accounting.received.satoshis).to be < 100_000_000
          expect(group.channel.accounting.unsettled.millisatoshis).to eq(0)
          expect(group.channel.accounting.unsettled.satoshis).to eq(0)

          expect(group.channel.myself.node._key.size).to eq(64)
          expect(group.channel.myself.node.myself?).to be(true)
          expect(group.channel.myself.node.alias).to eq('icebaker/old-stone')
          expect(group.channel.myself.node.public_key).to eq('02d3c80335a8ccb2ed364c06875f32240f36f7edb37d80f8dbe321b4c364b6e997')
          expect(group.channel.myself.node.color).to eq('#ff338f')
          expect(group.channel.myself.accounting.balance.millisatoshis).to be > 10_000_000
          expect(group.channel.myself.accounting.balance.millisatoshis).to be < 200_000_000
          expect(group.channel.myself.accounting.balance.satoshis).to be > 10_000
          expect(group.channel.myself.accounting.balance.satoshis).to be < 200_000
          expect(group.channel.myself.policy.fee.base.millisatoshis).to be >= 0
          expect(group.channel.myself.policy.fee.base.satoshis).to be >= 0
          expect(group.channel.myself.policy.fee.rate.parts_per_million).to be >= 0
          expect(group.channel.myself.policy.fee.rate.percentage).to be >= 0
          expect(group.channel.myself.policy.htlc.minimum.millisatoshis).to eq(1000)
          expect(group.channel.myself.policy.htlc.minimum.satoshis).to eq(1)
          expect(group.channel.myself.policy.htlc.maximum.millisatoshis).to eq(6_045_000_000)
          expect(group.channel.myself.policy.htlc.maximum.satoshis).to eq(6_045_000)
          expect(group.channel.myself.node.platform.blockchain).to eq('bitcoin')
          expect(group.channel.myself.node.platform.network).to eq('mainnet')
          expect(group.channel.myself.node.platform.lightning.implementation).to eq('lnd')
          expect(group.channel.myself.node.platform.lightning.version).to eq('0.15.5-beta commit=v0.15.5-beta')

          expect(group.channel.partner.node._key.size).to eq(64)
          expect(group.channel.partner.node.myself?).to be(false)
          expect(group.channel.partner.node.alias).to eq('deezy.io ⚡✨')
          expect(group.channel.partner.node.public_key).to eq('024bfaf0cabe7f874fd33ebf7c6f4e5385971fc504ef3f492432e9e3ec77e1b5cf')
          expect(group.channel.partner.node.color).to eq('#3399ff')
          expect(group.channel.partner.accounting.balance.millisatoshis).to be > 10_000_000
          expect(group.channel.partner.accounting.balance.millisatoshis).to be < 200_000_000
          expect(group.channel.partner.accounting.balance.satoshis).to be > 10_000
          expect(group.channel.partner.accounting.balance.satoshis).to be < 200_000
          expect(group.channel.partner.policy.fee.base.millisatoshis).to eq(0)
          expect(group.channel.partner.policy.fee.base.satoshis).to eq(0)
          expect(group.channel.partner.policy.fee.rate.parts_per_million).to eq(0)
          expect(group.channel.partner.policy.fee.rate.percentage).to eq(0.0)
          expect(group.channel.partner.policy.htlc.minimum.millisatoshis).to eq(1000)
          expect(group.channel.partner.policy.htlc.minimum.satoshis).to eq(1)
          expect(group.channel.partner.policy.htlc.maximum.millisatoshis).to eq(6_039_752_000)
          expect(group.channel.partner.policy.htlc.maximum.satoshis).to eq(6_039_752)
          expect(group.channel.partner.node.platform.blockchain).to eq('bitcoin')
          expect(group.channel.partner.node.platform.network).to eq('mainnet')

          expect { group.channel.partner.node.platform.lightning }.to raise_error(
            NotYourNodeError
          )

          Contract.expect(
            group.to_h, 'c0655bde7bc059f62eb26c37e19c3e6f3f9cd3b9380c82d516c291cbca5b3c54'
          ) do |actual, expected|
            expect(actual.hash).to eq(expected.hash)
            expect(actual.contract).to eq(expected.contract)
          end
        end
      end

      context 'lost peer' do
        it 'models' do
          group = described_class.new(
            data.find { |d| !d[:channel][:known] },
            Lighstorm::Controller::Lightning::Forward.components
          )

          expect(group._key.size).to eq(64)

          expect(group.last_at).to be_a(Time)
          expect(group.last_at.utc.to_s).to eq('2023-01-17 14:47:11 UTC')

          # ------------------------------------------------------------------

          expect(group.analysis.count).to eq(14)

          expect(group.analysis.sums.amount.millisatoshis).to eq(2_146_315_420)
          expect(group.analysis.sums.amount.satoshis).to eq(2_146_315.42)
          expect(group.analysis.sums.fee.millisatoshis).to eq(116_195)
          expect(group.analysis.sums.fee.satoshis).to eq(116.195)

          expect(group.analysis.averages.amount.millisatoshis).to eq(153_308_244.2857143)
          expect(group.analysis.averages.amount.satoshis).to eq(153_308.2442857143)
          expect(group.analysis.averages.fee.millisatoshis).to eq(8299.642857142857)
          expect(group.analysis.averages.fee.satoshis).to eq(8.299642857142857)

          # ------------------------------------------------------------------

          expect(group.channel._key.size).to eq(64)
          expect(group.channel.known?).to be(false)

          expect { group.channel.mine? }.to raise_error(UnknownChannelError)
          expect { group.channel.opened_at }.to raise_error(UnknownChannelError)
          expect { group.channel.up_at }.to raise_error(UnknownChannelError)
          expect { group.channel.state }.to raise_error(UnknownChannelError)
          expect { group.channel.active? }.to raise_error(UnknownChannelError)
          expect { group.channel.exposure }.to raise_error(UnknownChannelError)
          expect { group.channel.accounting }.to raise_error(UnknownChannelError)
          expect { group.channel.myself }.to raise_error(UnknownChannelError)
          expect { group.channel.partner }.to raise_error(UnknownChannelError)

          Contract.expect(
            group.to_h, '119b2ce8c7412307313c8794ec5fb6ca84c03236f83648a1a092b4f766fd53b4'
          ) do |actual, expected|
            expect(actual.hash).to eq(expected.hash)
            expect(actual.contract).to eq(expected.contract)
          end
        end
      end
    end

    context 'hours-ago filter' do
      let(:data) do
        data = Lighstorm::Controller::Lightning::Forward::GroupByChannel.data(
          Lighstorm::Controller::Lightning::Forward.components,
          hours_ago: 24
        ) do |fetch|
          VCR.tape.replay('Controller::Lightning::Forward.group_by_channel', hours_ago: 24) { fetch.call }
        end
      end

      it 'filters' do
        expect(data.class).to eq(Array)
      end
    end
  end
end
