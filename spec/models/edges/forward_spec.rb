# frozen_string_literal: true

require 'json'

# Circular dependency issue:
# https://stackoverflow.com/questions/8057625/ruby-how-to-require-correctly-to-avoid-circular-dependencies
require_relative '../../../models/edges/channel/hop'

require_relative '../../../controllers/forward'
require_relative '../../../controllers/forward/all'

require_relative '../../../models/edges/forward'

require_relative '../../../ports/dsl/lighstorm/errors'

RSpec.describe Lighstorm::Models::Forward do
  describe 'all' do
    context 'known peer' do
      it 'models' do
        data = Lighstorm::Controllers::Forward::All.data(
          Lighstorm::Controllers::Forward.components
        ) do |fetch|
          VCR.tape.replay('Controllers::Forward.all.last/known-peer') do
            data = fetch.call

            channels = data[:get_chan_info].keys.filter do |key|
              !data[:get_chan_info][key][:_error]
            end

            data[:forwarding_history] = [
              data[:forwarding_history].reverse.find do |forward|
                channels.include?(forward[:chan_id_in]) && channels.include?(forward[:chan_id_out])
              end
            ]
            data
          end
        end

        forward = described_class.new(data[0])

        expect(forward._key.size).to eq(64)

        expect(forward.at).to be_a(Time)
        expect(forward.at.utc.to_s).to eq('2023-01-23 01:02:28 UTC')

        expect(forward.fee.millisatoshis).to eq(350)
        expect(forward.fee.satoshis).to eq(0.35)

        expect(forward.in.amount.millisatoshis).to eq(5_000_850)
        expect(forward.in.amount.satoshis).to eq(5000.85)

        expect(forward.out.amount.millisatoshis).to eq(5_000_500)
        expect(forward.out.amount.satoshis).to eq(5000.5)

        expect(
          forward.in.amount.millisatoshis - forward.out.amount.millisatoshis
        ).to eq(forward.fee.millisatoshis)

        # ------------------------------------------------------------------

        expect(forward.in.channel._key.size).to eq(64)
        expect(forward.in.channel.known?).to be(true)
        expect(forward.in.channel.mine?).to be(true)

        expect(forward.in.channel.id).to eq('850099509773795329')
        expect(forward.in.channel.opened_at).to be_a(Time)
        expect(forward.in.channel.opened_at.utc.to_s.size).to eq(23)
        expect(forward.in.channel.up_at).to be_a(Time)
        expect(forward.in.channel.up_at.utc.to_s.size).to eq(23)
        expect(forward.in.channel.up_at).to be > forward.in.channel.opened_at
        expect(forward.in.channel.state).to be('active')
        expect(forward.in.channel.active?).to be(true)
        expect(forward.in.channel.exposure).to eq('public')

        expect(forward.in.channel.accounting.capacity.millisatoshis).to eq(6_300_000_000)
        expect(forward.in.channel.accounting.capacity.satoshis).to eq(6_300_000)
        expect(forward.in.channel.accounting.sent.millisatoshis).to eq(49_124_312_000)
        expect(forward.in.channel.accounting.sent.satoshis).to eq(49_124_312)
        expect(forward.in.channel.accounting.received.millisatoshis).to be > 45_000_000_000
        expect(forward.in.channel.accounting.received.satoshis).to be > 45_000_000
        expect(forward.in.channel.accounting.unsettled.millisatoshis).to eq(0)
        expect(forward.in.channel.accounting.unsettled.satoshis).to eq(0)

        expect(forward.in.channel.myself.node._key.size).to eq(64)
        expect(forward.in.channel.myself.node.myself?).to be(true)
        expect(forward.in.channel.myself.node.alias).to eq('icebaker/old-stone')
        expect(forward.in.channel.myself.node.public_key).to eq('02d3c80335a8ccb2ed364c06875f32240f36f7edb37d80f8dbe321b4c364b6e997')
        expect(forward.in.channel.myself.node.color).to eq('#ff338f')
        expect(forward.in.channel.myself.accounting.balance.millisatoshis).to be > 500_000_000
        expect(forward.in.channel.myself.accounting.balance.millisatoshis).to be < 10_000_000_000
        expect(forward.in.channel.myself.accounting.balance.satoshis).to be > 500_000
        expect(forward.in.channel.myself.accounting.balance.satoshis).to be < 10_000_000
        expect(forward.in.channel.myself.policy.fee.base.millisatoshis).to eq(0)
        expect(forward.in.channel.myself.policy.fee.base.satoshis).to eq(0)
        expect(forward.in.channel.myself.policy.fee.rate.parts_per_million).to eq(5)
        expect(forward.in.channel.myself.policy.fee.rate.percentage).to eq(0.0005)
        expect(forward.in.channel.myself.policy.htlc.minimum.millisatoshis).to eq(1000)
        expect(forward.in.channel.myself.policy.htlc.minimum.satoshis).to eq(1)
        expect(forward.in.channel.myself.policy.htlc.maximum.millisatoshis).to eq(6_045_000_000)
        expect(forward.in.channel.myself.policy.htlc.maximum.satoshis).to eq(6_045_000)
        expect(forward.in.channel.myself.node.platform.blockchain).to eq('bitcoin')
        expect(forward.in.channel.myself.node.platform.network).to eq('mainnet')
        expect(forward.in.channel.myself.node.platform.lightning.implementation).to eq('lnd')
        expect(forward.in.channel.myself.node.platform.lightning.version).to eq('0.15.5-beta commit=v0.15.5-beta')

        expect(forward.in.channel.partner.node._key.size).to eq(64)
        expect(forward.in.channel.partner.node.myself?).to be(false)
        expect(forward.in.channel.partner.node.alias).to eq('Boltz')
        expect(forward.in.channel.partner.node.public_key).to eq('026165850492521f4ac8abd9bd8088123446d126f648ca35e60f88177dc149ceb2')
        expect(forward.in.channel.partner.node.color).to eq('#ff9800')
        expect(forward.in.channel.partner.accounting.balance.millisatoshis).to be > 500_000_000
        expect(forward.in.channel.partner.accounting.balance.millisatoshis).to be < 10_000_000_000
        expect(forward.in.channel.partner.accounting.balance.satoshis).to be > 500_000
        expect(forward.in.channel.partner.accounting.balance.satoshis).to be < 10_000_000
        expect(forward.in.channel.partner.policy.fee.base.millisatoshis).to eq(0)
        expect(forward.in.channel.partner.policy.fee.base.satoshis).to eq(0)
        expect(forward.in.channel.partner.policy.fee.rate.parts_per_million).to eq(1)
        expect(forward.in.channel.partner.policy.fee.rate.percentage).to eq(0.0001)
        expect(forward.in.channel.partner.policy.htlc.minimum.millisatoshis).to eq(1000)
        expect(forward.in.channel.partner.policy.htlc.minimum.satoshis).to eq(1)
        expect(forward.in.channel.partner.policy.htlc.maximum.millisatoshis).to eq(6_237_000_000)
        expect(forward.in.channel.partner.policy.htlc.maximum.satoshis).to eq(6_237_000)
        expect(forward.in.channel.partner.node.platform.blockchain).to eq('bitcoin')
        expect(forward.in.channel.partner.node.platform.network).to eq('mainnet')

        expect { forward.in.channel.partner.node.platform.lightning }.to raise_error(
          NotYourNodeError
        )

        # ------------------------------------------------------------------

        expect(forward.in.channel._key.size).to eq(64)
        expect(forward.in.channel.known?).to be(true)
        expect(forward.out.channel.mine?).to be(true)

        expect(forward.out.channel.id).to eq('848916435345801217')
        expect(forward.out.channel.opened_at).to be_a(Time)
        expect(forward.out.channel.opened_at.utc.to_s.size).to eq(23)
        expect(forward.out.channel.up_at).to be_a(Time)
        expect(forward.out.channel.up_at.utc.to_s.size).to eq(23)
        expect(forward.out.channel.up_at).to be > forward.out.channel.opened_at
        expect(forward.out.channel.state).to be('active')
        expect(forward.out.channel.active?).to be(true)
        expect(forward.out.channel.exposure).to eq('public')

        expect(forward.out.channel.accounting.capacity.millisatoshis).to eq(6_500_000_000)
        expect(forward.out.channel.accounting.capacity.satoshis).to eq(6_500_000)
        expect(forward.out.channel.accounting.sent.millisatoshis).to be > 7_000_000_000
        expect(forward.out.channel.accounting.sent.millisatoshis).to be < 70_000_000_000
        expect(forward.out.channel.accounting.sent.satoshis).to be > 7_000_000
        expect(forward.out.channel.accounting.sent.satoshis).to be < 70_000_000
        expect(forward.out.channel.accounting.received.millisatoshis).to be > 2_000_000_000
        expect(forward.out.channel.accounting.received.millisatoshis).to be < 20_000_000_000
        expect(forward.out.channel.accounting.received.satoshis).to be > 2_000_000
        expect(forward.out.channel.accounting.received.satoshis).to be < 20_000_000
        expect(forward.out.channel.accounting.unsettled.millisatoshis).to eq(0)
        expect(forward.out.channel.accounting.unsettled.satoshis).to eq(0)

        expect(forward.out.channel.myself.node._key.size).to eq(64)
        expect(forward.out.channel.myself.node.myself?).to be(true)
        expect(forward.out.channel.myself.node.alias).to eq('icebaker/old-stone')
        expect(forward.out.channel.myself.node.public_key).to eq('02d3c80335a8ccb2ed364c06875f32240f36f7edb37d80f8dbe321b4c364b6e997')
        expect(forward.out.channel.myself.node.color).to eq('#ff338f')

        expect(forward.in.channel.myself.accounting.balance.millisatoshis).to be > 500_000_000
        expect(forward.in.channel.myself.accounting.balance.millisatoshis).to be < 10_000_000_000
        expect(forward.in.channel.myself.accounting.balance.satoshis).to be > 500_000
        expect(forward.in.channel.myself.accounting.balance.satoshis).to be < 10_000_000

        expect(forward.out.channel.myself.policy.fee.base.millisatoshis).to eq(0)
        expect(forward.out.channel.myself.policy.fee.base.satoshis).to eq(0)
        expect(forward.out.channel.myself.policy.fee.rate.parts_per_million).to eq(874)
        expect(forward.out.channel.myself.policy.fee.rate.percentage).to eq(0.0874)
        expect(forward.out.channel.myself.policy.htlc.minimum.millisatoshis).to eq(1000)
        expect(forward.out.channel.myself.policy.htlc.minimum.satoshis).to eq(1)
        expect(forward.out.channel.myself.policy.htlc.maximum.millisatoshis).to eq(6_045_000_000)
        expect(forward.out.channel.myself.policy.htlc.maximum.satoshis).to eq(6_045_000)
        expect(forward.out.channel.myself.node.platform.blockchain).to eq('bitcoin')
        expect(forward.out.channel.myself.node.platform.network).to eq('mainnet')
        expect(forward.out.channel.myself.node.platform.lightning.implementation).to eq('lnd')
        expect(forward.out.channel.myself.node.platform.lightning.version).to eq('0.15.5-beta commit=v0.15.5-beta')

        expect(forward.out.channel.partner.node._key.size).to eq(64)
        expect(forward.out.channel.partner.node.myself?).to be(false)
        expect(forward.out.channel.partner.node.alias).to eq('WalletOfSatoshi.com')
        expect(forward.out.channel.partner.node.public_key).to eq('035e4ff418fc8b5554c5d9eea66396c227bd429a3251c8cbc711002ba215bfc226')
        expect(forward.out.channel.partner.node.color).to eq('#3399ff')

        expect(forward.in.channel.partner.accounting.balance.millisatoshis).to be > 500_000_000
        expect(forward.in.channel.partner.accounting.balance.millisatoshis).to be < 10_000_000_000
        expect(forward.in.channel.partner.accounting.balance.satoshis).to be > 500_000
        expect(forward.in.channel.partner.accounting.balance.satoshis).to be < 10_000_000

        expect(forward.out.channel.partner.policy.fee.base.millisatoshis).to eq(0)
        expect(forward.out.channel.partner.policy.fee.base.satoshis).to eq(0)
        expect(forward.out.channel.partner.policy.fee.rate.parts_per_million).to eq(300)
        expect(forward.out.channel.partner.policy.fee.rate.percentage).to eq(0.03)
        expect(forward.out.channel.partner.policy.htlc.minimum.millisatoshis).to eq(1000)
        expect(forward.out.channel.partner.policy.htlc.minimum.satoshis).to eq(1)
        expect(forward.out.channel.partner.policy.htlc.maximum.millisatoshis).to eq(6_435_000_000)
        expect(forward.out.channel.partner.policy.htlc.maximum.satoshis).to eq(6_435_000)
        expect(forward.out.channel.partner.node.platform.blockchain).to eq('bitcoin')
        expect(forward.out.channel.partner.node.platform.network).to eq('mainnet')

        expect { forward.out.channel.partner.node.platform.lightning }.to raise_error(
          NotYourNodeError
        )

        Contract.expect(
          forward.to_h,
          'b469aaa041f93dc3a6bd20e596c3d29480b5615ecf7972378dbe98791dcfd2e5'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)
        end
      end
    end

    context 'lost peer' do
      it 'models' do
        data = Lighstorm::Controllers::Forward::All.data(
          Lighstorm::Controllers::Forward.components
        ) do |fetch|
          VCR.tape.replay('Controllers::Forward.all.last/lost-peer') do
            data = fetch.call

            channels = data[:get_chan_info].keys.filter do |key|
              !data[:get_chan_info][key][:_error]
            end

            data[:forwarding_history] = [
              data[:forwarding_history].reverse.find do |forward|
                !channels.include?(forward[:chan_id_in]) && !channels.include?(forward[:chan_id_out])
              end
            ]
            data
          end
        end

        forward = described_class.new(data[0])

        expect(forward._key.size).to eq(64)

        expect(forward.at).to be_a(Time)
        expect(forward.at.utc.to_s).to eq('2023-01-16 14:49:43 UTC')

        expect(forward.fee.millisatoshis).to eq(5206)
        expect(forward.fee.satoshis).to eq(5.206)

        expect(forward.in.amount.millisatoshis).to eq(69_428_816)
        expect(forward.in.amount.satoshis).to eq(69_428.816)

        expect(forward.out.amount.millisatoshis).to eq(69_423_610)
        expect(forward.out.amount.satoshis).to eq(69_423.61)

        expect(
          forward.in.amount.millisatoshis - forward.out.amount.millisatoshis
        ).to eq(forward.fee.millisatoshis)

        # ------------------------------------------------------------------

        expect(forward.in.channel._key.size).to eq(64)
        expect(forward.in.channel.id).to eq('848952719119024129')

        expect(forward.in.channel.known?).to be(false)

        expect { forward.in.channel.mine? }.to raise_error(UnknownChannelError)
        expect { forward.in.channel.opened_at }.to raise_error(UnknownChannelError)
        expect { forward.in.channel.up_at }.to raise_error(UnknownChannelError)
        expect { forward.in.channel.state }.to raise_error(UnknownChannelError)
        expect { forward.in.channel.active? }.to raise_error(UnknownChannelError)
        expect { forward.in.channel.exposure }.to raise_error(UnknownChannelError)
        expect { forward.in.channel.accounting }.to raise_error(UnknownChannelError)
        expect { forward.in.channel.myself }.to raise_error(UnknownChannelError)
        expect { forward.in.channel.partner }.to raise_error(UnknownChannelError)

        # ------------------------------------------------------------------

        expect(forward.out.channel._key.size).to eq(64)
        expect(forward.out.channel.id).to eq('848952719173877762')

        expect(forward.in.channel.known?).to be(false)

        expect { forward.out.channel.mine? }.to raise_error(UnknownChannelError)
        expect { forward.out.channel.opened_at }.to raise_error(UnknownChannelError)
        expect { forward.out.channel.up_at }.to raise_error(UnknownChannelError)
        expect { forward.out.channel.state }.to raise_error(UnknownChannelError)
        expect { forward.out.channel.active? }.to raise_error(UnknownChannelError)
        expect { forward.out.channel.exposure }.to raise_error(UnknownChannelError)
        expect { forward.out.channel.accounting }.to raise_error(UnknownChannelError)
        expect { forward.out.channel.myself }.to raise_error(UnknownChannelError)
        expect { forward.out.channel.partner }.to raise_error(UnknownChannelError)

        Contract.expect(
          forward.to_h, 'febd1bd40e081685c5000faa98249d6760e37377f96600736a0a14f766176c19'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)
        end
      end
    end
  end
end
