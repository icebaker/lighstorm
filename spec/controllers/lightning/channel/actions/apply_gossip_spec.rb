# frozen_string_literal: true

require 'json'

# Circular dependency issue:
# https://stackoverflow.com/questions/8057625/ruby-how-to-require-correctly-to-avoid-circular-dependencies
require_relative '../../../../../models/lightning/edges/channel/hop'
require_relative '../../../../../models/lightning/edges/channel'
require_relative '../../../../../controllers/lightning/channel/find_by_id'
require_relative '../../../../../ports/dsl/lighstorm/errors'

RSpec.describe Lighstorm::Model::Lightning::Channel do
  describe '.apply!' do
    let(:channel) do
      data = Lighstorm::Controller::Lightning::Channel::FindById.data(
        Lighstorm::Controller::Lightning::Channel.components,
        channel_id
      ) do |fetch|
        VCR.tape.replay("Controller::Lightning::Channel.find_by_id/#{channel_id}") { fetch.call }
      end

      described_class.new(data, nil)
    end

    context 'complete without changes A' do
      let(:channel_id) { 118_747_255_865_345 }

      it 'applies the gossip' do
        previous_dump = channel.dump

        gossip = JSON.parse(TestData.read('spec/data/gossip/channel/sample-a.json'))

        diff = channel.apply!(gossip: gossip)

        expect(diff).to eq([])

        expect(channel.dump).to eq(previous_dump)
      end
    end

    context 'complete with changes error B' do
      let(:channel_id) { 118_747_255_865_345 }

      it 'applies the gossip' do
        previous_dump = channel.dump

        gossip = JSON.parse(TestData.read('spec/data/gossip/channel/sample-b.json'))

        expect { channel.apply!(gossip: gossip) }.to raise_error(
          IncoherentGossipError, "Gossip doesn't belong to this Channel"
        )
      end
    end

    context 'complete with changes B' do
      let(:channel_id) { 197_912_093_065_217 }

      it 'applies the gossip' do
        previous_to_h = channel.to_h
        previous_dump = channel.dump

        gossip = JSON.parse(TestData.read('spec/data/gossip/channel/sample-b.json'))

        expect(channel.partners[0].policy.fee.base.millisatoshis).not_to eq(150)

        diff = channel.apply!(gossip: gossip)

        expect(channel.partners[0].policy.fee.base.millisatoshis).to eq(150)

        expect(diff).to eq(
          [{ from: 1000, path: [:partners, 0, :policy, :fee, :base, :millisatoshis], to: 150 }]
        )

        expect(channel.to_h).not_to eq(previous_to_h)
        expect(channel.dump).not_to eq(previous_dump)
      end
    end

    context 'complete with changes C' do
      let(:channel_id) { 197_912_093_065_217 }

      it 'applies the gossip' do
        previous_to_h = channel.to_h
        previous_dump = channel.dump

        gossip = JSON.parse(TestData.read('spec/data/gossip/channel/sample-c.json'))

        expect(channel.partners[0].state).not_to eq('inactive')

        diff = channel.apply!(gossip: gossip)

        expect(channel.partners[0].state).to eq('inactive')

        expect(diff).to eq(
          [{ from: 'active', path: [:partners, 0, :state], to: 'inactive' }]
        )

        expect(channel.to_h).not_to eq(previous_to_h)
        expect(channel.dump).not_to eq(previous_dump)
      end
    end

    context 'all fields D' do
      let(:channel_id) { 118_747_255_865_345 }

      it 'applies the gossip' do
        previous_to_h = channel.to_h
        previous_dump = channel.dump

        gossip = JSON.parse(TestData.read('spec/data/gossip/channel/sample-d.json'))

        Contract.expect(
          previous_to_h, 'e1bd512fc7f42e8aa18becec404281c947b10fc27a0b4ccec331bfb9dece54ce'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)
        end

        Contract.expect(
          previous_dump, 'effb7584252b1a2b0dfebbf84c4b12b4228c33e0098b663719731e517613b683'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)
        end

        expect(channel.accounting.capacity.millisatoshis).not_to eq(6_000_000_000)

        expect(channel.partners[0].state).not_to eq('inactive')

        expect(channel.partners[0].policy.fee.base.millisatoshis).not_to eq(1700)
        expect(channel.partners[0].policy.fee.rate.parts_per_million).not_to eq(800)

        expect(channel.partners[0].policy.htlc.maximum.millisatoshis).not_to eq(5_950_000_000)
        expect(channel.partners[0].policy.htlc.minimum.millisatoshis).not_to eq(1400)
        expect(channel.partners[0].policy.htlc.blocks.delta.minimum).not_to eq(200)

        diff = channel.apply!(gossip: gossip)

        expect(channel.accounting.capacity.millisatoshis).to eq(6_000_000_000)

        expect(channel.partners[0].state).to eq('inactive')

        expect(channel.partners[0].policy.fee.base.millisatoshis).to eq(1700)
        expect(channel.partners[0].policy.fee.rate.parts_per_million).to eq(800)

        expect(channel.partners[0].policy.htlc.maximum.millisatoshis).to eq(5_950_000_000)
        expect(channel.partners[0].policy.htlc.minimum.millisatoshis).to eq(1400)
        expect(channel.partners[0].policy.htlc.blocks.delta.minimum).to eq(200)

        expect(diff).to eq(
          [{ path: %i[accounting capacity millisatoshis], from: 250_000_000, to: 6_000_000_000 },
           { path: [:partners, 0, :policy, :fee, :base, :millisatoshis], from: 1000, to: 1700 },
           { path: [:partners, 0, :policy, :fee, :rate, :parts_per_million], from: 1, to: 800 },
           { path: [:partners, 0, :policy, :htlc, :minimum, :millisatoshis], from: 1000, to: 1400 },
           { path: [:partners, 0, :policy, :htlc, :maximum, :millisatoshis], from: 247_500_000,
             to: 5_950_000_000 },
           { path: [:partners, 0, :policy, :htlc, :blocks, :delta, :minimum], from: 40, to: 200 },
           { path: [:partners, 0, :state], from: 'active', to: 'inactive' }]
        )

        expect(channel.to_h).not_to eq(previous_to_h)
        expect(channel.dump).not_to eq(previous_dump)

        Contract.expect(
          channel.to_h, 'e1bd512fc7f42e8aa18becec404281c947b10fc27a0b4ccec331bfb9dece54ce'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)
        end

        Contract.expect(
          channel.dump, 'effb7584252b1a2b0dfebbf84c4b12b4228c33e0098b663719731e517613b683'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)
        end
      end
    end

    context 'from empty' do
      it 'applies the gossip' do
        gossip = JSON.parse(TestData.read('spec/data/gossip/channel/sample-d.json'))

        channel = described_class.adapt(gossip: gossip)

        Contract.expect(
          channel.to_h, '8893858c52d717ae64d1fc160da399fb031735241e7e6838f727226fa1508ebc'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)
        end

        Contract.expect(
          channel.dump, '495c462e06f2a04c0a95b803653b5ed5a896f76e758cdcbbb2630bc7dc25cbd7'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)
        end

        expect { channel.apply!(gossip: gossip) }.not_to raise_error
      end
    end
  end
end
