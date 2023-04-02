# frozen_string_literal: true

require 'json'

require_relative '../../../../../controllers/lightning/node'
require_relative '../../../../../controllers/lightning/node/myself'
require_relative '../../../../../controllers/lightning/node/find_by_public_key'
require_relative '../../../../../controllers/lightning/node/all'

require_relative '../../../../../models/lightning/nodes/node'

require_relative '../../../../../ports/dsl/lighstorm/errors'

RSpec.describe Lighstorm::Model::Lightning::Node do
  describe '.dump' do
    context 'samples' do
      let(:data) do
        myself = Lighstorm::Controller::Lightning::Node::Myself.data(
          Lighstorm::Controller::Lightning::Node.components
        ) do |fetch|
          VCR.tape.replay('Controller::Lightning::Node.myself') { fetch.call }
        end

        data = Lighstorm::Controller::Lightning::Node::All.data(
          Lighstorm::Controller::Lightning::Node.components
        ) do |fetch|
          VCR.tape.replay('Controller::Lightning::Node.all/samples') do
            data = fetch.call

            data[:describe_graph] = [
              data[:describe_graph].find { |n| n.alias != '' && n.pub_key != myself[:public_key] },
              data[:describe_graph].find { |n| n.alias == '' && n.pub_key != myself[:public_key] },
              data[:describe_graph].find { |n| n.pub_key == myself[:public_key] }
            ].map(&:to_h)

            data
          end
        end
      end

      it 'provides data portability' do
        node_alias = described_class.new(data[0], Lighstorm::Controller::Lightning::Node.components)
        node_no_alias = described_class.new(data[1], Lighstorm::Controller::Lightning::Node.components)
        node_myself = described_class.new(data[2], Lighstorm::Controller::Lightning::Node.components)

        Contract.expect(
          node_alias.dump, 'e383c9cb552c7d960adb867d7d584be794687ca0d0f4e1089be16f64296b62b3'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)

          expect(actual.contract).to eq(
            { _key: 'String:50+',
              _source: 'Symbol:11..20',
              alias: 'String:11..20',
              color: 'String:0..10',
              myself: 'Boolean',
              platform: { blockchain: 'String:0..10', network: 'String:0..10' },
              public_key: 'String:50+' }
          )
        end

        Contract.expect(
          node_no_alias.dump, 'dd336ce8879b3461a2c4d0402f43467731f1464f9c4a6b207a41f140c7a810b4'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)

          expect(actual.contract).to eq(
            { _key: 'String:50+',
              _source: 'Symbol:11..20',
              alias: 'String:0..10',
              color: 'String:0..10',
              myself: 'Boolean',
              platform: { blockchain: 'String:0..10', network: 'String:0..10' },
              public_key: 'String:50+' }
          )
        end

        Contract.expect(
          node_myself.dump, '1106bdab8aa3864249b00dd9c74329ed36e88365fa9e04fafbf8ce714dde5aa7'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)

          expect(actual.contract).to eq(
            { _key: 'String:50+',
              _source: 'Symbol:0..10',
              alias: 'String:11..20',
              color: 'String:0..10',
              myself: 'Boolean',
              platform: {
                blockchain: 'String:0..10',
                lightning: {
                  implementation: 'String:0..10',
                  version: 'String:31..40'
                },
                network: 'String:0..10'
              },
              public_key: 'String:50+' }
          )
        end

        expect(node_alias.dump).to eq(
          described_class.new(node_alias.dump, Lighstorm::Controller::Lightning::Node.components).dump
        )
        expect(node_no_alias.dump).to eq(
          described_class.new(node_no_alias.dump, Lighstorm::Controller::Lightning::Node.components).dump
        )
        expect(node_myself.dump).to eq(
          described_class.new(node_myself.dump, Lighstorm::Controller::Lightning::Node.components).dump
        )

        expect(node_alias.to_h).to eq(
          described_class.new(node_alias.dump, Lighstorm::Controller::Lightning::Node.components).to_h
        )
        expect(node_no_alias.to_h).to eq(
          described_class.new(node_no_alias.dump, Lighstorm::Controller::Lightning::Node.components).to_h
        )
        expect(node_myself.to_h).to eq(
          described_class.new(node_myself.dump, Lighstorm::Controller::Lightning::Node.components).to_h
        )
      end
    end
  end
end
