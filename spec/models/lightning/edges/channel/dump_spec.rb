# frozen_string_literal: true

require 'json'

# Circular dependency issue:
# https://stackoverflow.com/questions/8057625/ruby-how-to-require-correctly-to-avoid-circular-dependencies
require_relative '../../../../../models/lightning/edges/channel/hop'
require_relative '../../../../../controllers/lightning/channel/mine'
require_relative '../../../../../controllers/lightning/channel/all'
require_relative '../../../../../controllers/lightning/channel/find_by_id'
require_relative '../../../../../adapters/lightning/edges/channel'

require_relative '../../../../../models/lightning/edges/channel'

require_relative '../../../../../ports/dsl/lighstorm/errors'

RSpec.describe Lighstorm::Model::Lightning::Channel do
  describe '.dump' do
    context 'popular' do
      it 'provides data portability' do
        channel_id = '118747255865345'

        data = Lighstorm::Controller::Lightning::Channel::FindById.data(
          Lighstorm::Controller::Lightning::Channel.components,
          channel_id
        ) do |fetch|
          VCR.tape.replay("Controller::Lightning::Channel.find_by_id/#{channel_id}") { fetch.call }
        end

        channel = described_class.new(data, Lighstorm::Controller::Lightning::Channel.components)

        Contract.expect(
          channel.dump, 'effb7584252b1a2b0dfebbf84c4b12b4228c33e0098b663719731e517613b683'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)
        end

        expect(channel.dump).to eq(
          described_class.new(channel.dump, Lighstorm::Controller::Lightning::Channel.components).dump
        )

        expect(channel.to_h).to eq(
          described_class.new(channel.dump, Lighstorm::Controller::Lightning::Channel.components).to_h
        )
      end
    end

    context 'mine' do
      it 'models' do
        data = Lighstorm::Controller::Lightning::Channel::Mine.data(
          Lighstorm::Controller::Lightning::Channel.components
        ) do |fetch|
          VCR.tape.replay('Controller::Lightning::Channel.mine') do
            data = fetch.call
            data[:list_channels] = [data[:list_channels][0].to_h]
            data
          end
        end

        channel = described_class.new(data[0], Lighstorm::Controller::Lightning::Channel.components)

        Contract.expect(
          channel.dump, 'd4fff89949b73f8bd56cae278eac2750b19002c715722e922293219e15f51cab'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)
        end

        expect(channel.dump).to eq(
          described_class.new(channel.dump, Lighstorm::Controller::Lightning::Channel.components).dump
        )

        expect(channel.to_h).to eq(
          described_class.new(channel.dump, Lighstorm::Controller::Lightning::Channel.components).to_h
        )
      end
    end

    context 'gossip B' do
      it 'provides data portability' do
        gossip = JSON.parse(TestData.read('spec/data/gossip/channel/sample-b.json'))

        channel = described_class.new(
          Lighstorm::Adapter::Lightning::Channel.subscribe_channel_graph(gossip),
          Lighstorm::Controller::Lightning::Channel.components
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

        expect(channel.dump).to eq(
          described_class.new(channel.dump, Lighstorm::Controller::Lightning::Channel.components).dump
        )

        expect(channel.to_h).to eq(
          described_class.new(channel.dump, Lighstorm::Controller::Lightning::Channel.components).to_h
        )
      end
    end

    context 'gossip A' do
      it 'provides data portability' do
        gossip = JSON.parse(TestData.read('spec/data/gossip/channel/sample-a.json'))

        channel = described_class.new(
          Lighstorm::Adapter::Lightning::Channel.subscribe_channel_graph(gossip),
          Lighstorm::Controller::Lightning::Channel.components
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

        expect(channel.dump).to eq(
          described_class.new(channel.dump, Lighstorm::Controller::Lightning::Channel.components).dump
        )

        expect(channel.to_h).to eq(
          described_class.new(channel.dump, Lighstorm::Controller::Lightning::Channel.components).to_h
        )
      end
    end

    context 'gossip C' do
      it 'provides data portability' do
        gossip = JSON.parse(TestData.read('spec/data/gossip/channel/sample-c.json'))

        channel = described_class.new(
          Lighstorm::Adapter::Lightning::Channel.subscribe_channel_graph(gossip),
          Lighstorm::Controller::Lightning::Channel.components
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

        expect(channel.dump).to eq(
          described_class.new(channel.dump, Lighstorm::Controller::Lightning::Channel.components).dump
        )

        expect(channel.to_h).to eq(
          described_class.new(channel.dump, Lighstorm::Controller::Lightning::Channel.components).to_h
        )
      end
    end
  end
end
