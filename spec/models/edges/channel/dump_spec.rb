# frozen_string_literal: true

require 'json'

require_relative '../../../../controllers/channel/mine'
require_relative '../../../../controllers/channel/all'
require_relative '../../../../controllers/channel/find_by_id'
require_relative '../../../../adapters/edges/channel'

require_relative '../../../../models/edges/channel'

require_relative '../../../../ports/dsl/lighstorm/errors'

RSpec.describe Lighstorm::Models::Channel do
  describe '.dump' do
    context 'popular' do
      it 'provides data portability' do
        channel_id = '853996178921881601'

        data = Lighstorm::Controllers::Channel::FindById.data(channel_id) do |fetch|
          VCR.tape.replay("Controllers::Channel.find_by_id/#{channel_id}") { fetch.call }
        end

        channel = described_class.new(data)

        Contract.expect(
          channel.dump, '37500d995a8fae10335094e07898002e60a432be7ec879fe907704cc0a17a2ea'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)

          expect(actual.contract).to eq(
            { _key: 'String:50+',
              _source: 'Symbol:11..20',
              accounting: { capacity: { millisatoshis: 'Integer:11..20' } },
              exposure: 'String:0..10',
              id: 'String:11..20',
              known: 'Boolean',
              mine: 'Boolean',
              partners: [
                { _source: 'Symbol:11..20',
                  node: {
                    _key: 'String:50+',
                    _source: 'Symbol:11..20',
                    alias: 'String:11..20',
                    color: 'String:0..10',
                    myself: 'Boolean',
                    platform: {
                      blockchain: 'String:0..10',
                      network: 'String:0..10'
                    },
                    public_key: 'String:50+'
                  },
                  policy: {
                    fee: {
                      base: { millisatoshis: 'Integer:0..10' },
                      rate: { parts_per_million: 'Integer:0..10' }
                    },
                    htlc: {
                      blocks: { delta: { minimum: 'Integer:0..10' } },
                      maximum: { millisatoshis: 'Integer:11..20' },
                      minimum: { millisatoshis: 'Integer:0..10' }
                    }
                  },
                  state: 'String:0..10' },
                { _source: 'Symbol:11..20',
                  node: {
                    _key: 'String:50+',
                    _source: 'Symbol:11..20',
                    alias: 'String:11..20',
                    color: 'String:0..10',
                    myself: 'Boolean',
                    platform: {
                      blockchain: 'String:0..10',
                      network: 'String:0..10'
                    },
                    public_key: 'String:50+'
                  },
                  policy: {
                    fee: {
                      base: { millisatoshis: 'Integer:0..10' },
                      rate: { parts_per_million: 'Integer:0..10' }
                    },
                    htlc: {
                      blocks: { delta: { minimum: 'Integer:0..10' } },
                      maximum: { millisatoshis: 'Integer:11..20' },
                      minimum: { millisatoshis: 'Integer:0..10' }
                    }
                  },
                  state: 'String:0..10' }
              ] }
          )
        end

        expect(channel.dump).to eq(described_class.new(channel.dump).dump)
        expect(channel.to_h).to eq(described_class.new(channel.dump).to_h)
      end
    end

    context 'mine' do
      it 'models' do
        data = Lighstorm::Controllers::Channel::Mine.data do |fetch|
          VCR.tape.replay('Controllers::Channel.mine') do
            data = fetch.call
            data[:list_channels] = [data[:list_channels][0].to_h]
            data
          end
        end

        channel = described_class.new(data[0])

        Contract.expect(
          channel.dump, 'a625dae9677bbb55775d943a9db73761d8d401a0283923b63b683e0d04a95dcd'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)

          expect(actual.contract).to eq(
            { _key: 'String:50+',
              _source: 'Symbol:11..20',
              accounting: {
                capacity: { millisatoshis: 'Integer:0..10' },
                received: { millisatoshis: 'Integer:11..20' },
                sent: { millisatoshis: 'Integer:11..20' },
                unsettled: { millisatoshis: 'Integer:0..10' }
              },
              exposure: 'String:0..10',
              id: 'String:11..20',
              known: 'Boolean',
              mine: 'Boolean',
              opened_at: 'Time',
              partners: [
                { _source: 'Symbol:11..20',
                  accounting: { balance: { millisatoshis: 'Integer:0..10' } },
                  node: {
                    _key: 'String:50+',
                    _source: 'Symbol:0..10',
                    alias: 'String:11..20',
                    color: 'String:0..10',
                    myself: 'Boolean',
                    platform: {
                      blockchain: 'String:0..10',
                      lightning: { implementation: 'String:0..10', version: 'String:31..40' },
                      network: 'String:0..10'
                    },
                    public_key: 'String:50+'
                  },
                  policy: {
                    fee: {
                      base: { millisatoshis: 'Integer:0..10' },
                      rate: { parts_per_million: 'Integer:0..10' }
                    },
                    htlc: {
                      blocks: { delta: { minimum: 'Integer:0..10' } },
                      maximum: { millisatoshis: 'Integer:0..10' },
                      minimum: { millisatoshis: 'Integer:0..10' }
                    }
                  },
                  state: 'String:0..10' },
                { _source: 'Symbol:11..20',
                  accounting: { balance: { millisatoshis: 'Integer:0..10' } },
                  node: {
                    _key: 'String:50+',
                    _source: 'Symbol:11..20',
                    alias: 'String:11..20',
                    color: 'String:0..10',
                    myself: 'Boolean',
                    platform: { blockchain: 'String:0..10', network: 'String:0..10' },
                    public_key: 'String:50+'
                  },
                  policy: {
                    fee: {
                      base: { millisatoshis: 'Integer:0..10' },
                      rate: { parts_per_million: 'Integer:0..10' }
                    },
                    htlc: {
                      blocks: { delta: { minimum: 'Integer:0..10' } },
                      maximum: { millisatoshis: 'Integer:0..10' },
                      minimum: { millisatoshis: 'Integer:0..10' }
                    }
                  },
                  state: 'String:0..10' }
              ],
              state: 'String:0..10',
              transaction: { funding: { id: 'String:50+', index: 'Integer:0..10' } },
              up_at: 'Time' }
          )
        end

        expect(channel.dump).to eq(described_class.new(channel.dump).dump)
        expect(channel.to_h).to eq(described_class.new(channel.dump).to_h)
      end
    end

    context 'gossip B' do
      it 'provides data portability' do
        gossip = JSON.parse(File.read('spec/data/gossip/channel/sample-b.json'))

        channel = described_class.new(
          Lighstorm::Adapter::Channel.subscribe_channel_graph(gossip)
        )

        Contract.expect(
          channel.dump, 'a47be8d6d54ecf51b55c738e1fc3cbba23c69ade69fb7124c00d22d682f7ccbb'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)

          expect(actual.contract).to eq(
            { _key: 'String:50+',
              _source: 'Symbol:21..30',
              accounting: { capacity: { millisatoshis: 'Integer:0..10' } },
              id: 'String:11..20',
              partners: [
                { _source: 'Symbol:21..30',
                  node: { public_key: 'String:50+' },
                  policy: {
                    _source: 'Symbol:21..30',
                    fee: {
                      base: { millisatoshis: 'Integer:0..10' }
                    },
                    htlc: {
                      blocks: { delta: { minimum: 'Integer:0..10' } },
                      maximum: { millisatoshis: 'Integer:0..10' },
                      minimum: { millisatoshis: 'Integer:0..10' }
                    }
                  } },
                { node: { public_key: 'String:50+' } }
              ] }
          )
        end

        expect(channel.dump).to eq(described_class.new(channel.dump).dump)
        expect(channel.to_h).to eq(described_class.new(channel.dump).to_h)
      end
    end

    context 'gossip A' do
      it 'provides data portability' do
        gossip = JSON.parse(File.read('spec/data/gossip/channel/sample-a.json'))

        channel = described_class.new(
          Lighstorm::Adapter::Channel.subscribe_channel_graph(gossip)
        )

        Contract.expect(
          channel.dump, 'f09efa5fa0c666794e64592f196761c8fb9ff815103316697fb73ee2170ef140'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)

          expect(actual.contract).to eq(
            { _key: 'String:50+',
              _source: 'Symbol:21..30',
              accounting: { capacity: { millisatoshis: 'Integer:0..10' } },
              id: 'String:11..20',
              partners: [{ _source: 'Symbol:21..30',
                           node: { public_key: 'String:50+' },
                           policy: { _source: 'Symbol:21..30',
                                     fee: { base: { millisatoshis: 'Integer:0..10' },
                                            rate: { parts_per_million: 'Integer:0..10' } },
                                     htlc: { blocks: { delta: { minimum: 'Integer:0..10' } }, maximum: { millisatoshis: 'Integer:0..10' },
                                             minimum: { millisatoshis: 'Integer:0..10' } } } },
                         { node: { public_key: 'String:50+' } }] }
          )
        end

        expect(channel.dump).to eq(described_class.new(channel.dump).dump)
        expect(channel.to_h).to eq(described_class.new(channel.dump).to_h)
      end
    end

    context 'gossip C' do
      it 'provides data portability' do
        gossip = JSON.parse(File.read('spec/data/gossip/channel/sample-c.json'))

        channel = described_class.new(
          Lighstorm::Adapter::Channel.subscribe_channel_graph(gossip)
        )

        Contract.expect(
          channel.dump, '98d710ac2ee1354cfae9577e2be804f05f3ad6d4396b6200e3ec11062a519da3'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)

          expect(actual.contract).to eq(
            { _key: 'String:50+',
              _source: 'Symbol:21..30',
              accounting: { capacity: { millisatoshis: 'Integer:0..10' } },
              id: 'String:11..20',
              partners: [{ _source: 'Symbol:21..30', node: { public_key: 'String:50+' }, state: 'String:0..10' },
                         { node: { public_key: 'String:50+' } }] }
          )
        end

        expect(channel.dump).to eq(described_class.new(channel.dump).dump)
        expect(channel.to_h).to eq(described_class.new(channel.dump).to_h)
      end
    end
  end
end
