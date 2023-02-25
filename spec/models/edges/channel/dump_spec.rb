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
          VCR.replay("Controllers::Channel.find_by_id/#{channel_id}") { fetch.call }
        end

        channel = described_class.new(data)

        Contract.expect(
          channel.dump, '511cbdca8d6e4e775614e856e1c77f0756a6f3d45f78f11da056643da590aff7'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)

          expect(actual.contract).to eq(
            { _key: 'String:50+',
              _source: 'Symbol:11..20',
              accounting: { capacity: { milisatoshis: 'Integer:11..20' } },
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
                      base: { milisatoshis: 'Integer:0..10' },
                      rate: { parts_per_million: 'Integer:0..10' }
                    },
                    htlc: {
                      blocks: { delta: { minimum: 'Integer:0..10' } },
                      maximum: { milisatoshis: 'Integer:11..20' },
                      minimum: { milisatoshis: 'Integer:0..10' }
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
                      base: { milisatoshis: 'Integer:0..10' },
                      rate: { parts_per_million: 'Integer:0..10' }
                    },
                    htlc: {
                      blocks: { delta: { minimum: 'Integer:0..10' } },
                      maximum: { milisatoshis: 'Integer:11..20' },
                      minimum: { milisatoshis: 'Integer:0..10' }
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
          VCR.replay('Controllers::Channel.mine') do
            data = fetch.call
            data[:list_channels] = [data[:list_channels][0].to_h]
            data
          end
        end

        channel = described_class.new(data[0])

        Contract.expect(
          channel.dump, '9f8c0a6458464c0bd746bbfec6f3975c1bbbee687d4f1d67792a9eefd2b45fb3'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)

          expect(actual.contract).to eq(
            { _key: 'String:50+',
              _source: 'Symbol:11..20',
              accounting: {
                capacity: { milisatoshis: 'Integer:0..10' },
                received: { milisatoshis: 'Integer:11..20' },
                sent: { milisatoshis: 'Integer:11..20' },
                unsettled: { milisatoshis: 'Integer:0..10' }
              },
              exposure: 'String:0..10',
              id: 'String:11..20',
              known: 'Boolean',
              mine: 'Boolean',
              opened_at: 'DateTime',
              partners: [
                { _source: 'Symbol:11..20',
                  accounting: { balance: { milisatoshis: 'Integer:0..10' } },
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
                      base: { milisatoshis: 'Integer:0..10' },
                      rate: { parts_per_million: 'Integer:0..10' }
                    },
                    htlc: {
                      blocks: { delta: { minimum: 'Integer:0..10' } },
                      maximum: { milisatoshis: 'Integer:0..10' },
                      minimum: { milisatoshis: 'Integer:0..10' }
                    }
                  },
                  state: 'String:0..10' },
                { _source: 'Symbol:11..20',
                  accounting: { balance: { milisatoshis: 'Integer:0..10' } },
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
                      base: { milisatoshis: 'Integer:0..10' },
                      rate: { parts_per_million: 'Integer:0..10' }
                    },
                    htlc: {
                      blocks: { delta: { minimum: 'Integer:0..10' } },
                      maximum: { milisatoshis: 'Integer:0..10' },
                      minimum: { milisatoshis: 'Integer:0..10' }
                    }
                  },
                  state: 'String:0..10' }
              ],
              state: 'String:0..10',
              transaction: { funding: { id: 'String:50+', index: 'Integer:0..10' } },
              up_at: 'DateTime' }
          )
        end

        expect(channel.dump).to eq(described_class.new(channel.dump).dump)
        expect(channel.to_h).to eq(described_class.new(channel.dump).to_h)

        params = {
          rate: { parts_per_million: channel.myself.policy.fee.rate.parts_per_million + 5 },
          base: { milisatoshis: channel.myself.policy.fee.base.milisatoshis + 7 }
        }

        channel.myself.policy.fee.update(params, preview: false, fake: true)

        expect(channel.myself.policy.fee.rate.parts_per_million).to eq(
          params[:rate][:parts_per_million]
        )

        expect(channel.myself.policy.fee.base.milisatoshis).to eq(
          params[:base][:milisatoshis]
        )

        copy = described_class.new(channel.dump)

        expect(copy.myself.policy.fee.rate.parts_per_million).to eq(
          params[:rate][:parts_per_million]
        )

        expect(copy.myself.policy.fee.base.milisatoshis).to eq(
          params[:base][:milisatoshis]
        )
      end
    end

    context 'gossip B' do
      it 'provides data portability' do
        gossip = JSON.parse(File.read('spec/data/gossip/channel/sample-b.json'))

        channel = described_class.new(
          Lighstorm::Adapter::Channel.subscribe_channel_graph(gossip)
        )

        Contract.expect(
          channel.dump, '978f0502508630bdef70857130fb02009550a614ea7c68b8010d6407c9de733e'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)

          expect(actual.contract).to eq(
            { _key: 'String:50+',
              _source: 'Symbol:21..30',
              accounting: { capacity: { milisatoshis: 'Integer:0..10' } },
              id: 'String:11..20',
              partners: [
                { _source: 'Symbol:21..30',
                  node: { public_key: 'String:50+' },
                  policy: {
                    _source: 'Symbol:21..30',
                    fee: {
                      base: { milisatoshis: 'Integer:0..10' }
                    },
                    htlc: {
                      blocks: { delta: { minimum: 'Integer:0..10' } },
                      maximum: { milisatoshis: 'Integer:0..10' },
                      minimum: { milisatoshis: 'Integer:0..10' }
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
          channel.dump, '741ae62ea22b48af83bef17336bf101755cc82c2f656882be0d098bf900e6de4'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)

          expect(actual.contract).to eq(
            { _key: 'String:50+',
              _source: 'Symbol:21..30',
              accounting: { capacity: { milisatoshis: 'Integer:0..10' } },
              id: 'String:11..20',
              partners: [{ _source: 'Symbol:21..30',
                           node: { public_key: 'String:50+' },
                           policy: { _source: 'Symbol:21..30',
                                     fee: { base: { milisatoshis: 'Integer:0..10' },
                                            rate: { parts_per_million: 'Integer:0..10' } },
                                     htlc: { blocks: { delta: { minimum: 'Integer:0..10' } }, maximum: { milisatoshis: 'Integer:0..10' },
                                             minimum: { milisatoshis: 'Integer:0..10' } } } },
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
          channel.dump, 'c4de9f110925bcd4186d9f624c9cf87488c7acf171f6d3b7c16bb9f4f8eb1146'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)

          expect(actual.contract).to eq(
            { _key: 'String:50+',
              _source: 'Symbol:21..30',
              accounting: { capacity: { milisatoshis: 'Integer:0..10' } },
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
