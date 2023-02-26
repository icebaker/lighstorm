# frozen_string_literal: true

require 'json'

require_relative '../../../controllers/node/myself'
require_relative '../../../controllers/node/find_by_public_key'
require_relative '../../../controllers/node/all'

require_relative '../../../models/nodes/node'

require_relative '../../../ports/dsl/lighstorm/errors'

RSpec.describe Lighstorm::Models::Node do
  describe '.myself' do
    it 'models' do
      data = Lighstorm::Controllers::Node::Myself.data do |fetch|
        VCR.tape.replay('Controllers::Node.myself') { fetch.call }
      end

      node = described_class.new(data)

      expect(node._key.size).to eq(64)
      expect(node.myself?).to be(true)
      expect(node.alias).to eq('icebaker/old-stone')
      expect(node.public_key).to eq('02d3c80335a8ccb2ed364c06875f32240f36f7edb37d80f8dbe321b4c364b6e997')
      expect(node.color).to eq('#ff338f')
      expect(node.platform.blockchain).to eq('bitcoin')
      expect(node.platform.network).to eq('mainnet')
      expect(node.platform.lightning.implementation).to eq('lnd')
      expect(node.platform.lightning.version).to eq('0.15.5-beta commit=v0.15.5-beta')

      Contract.expect(
        node.to_h, 'f7aee5d6bfb0f7a90e9658a4dcab3414c2d1689d1dfbaf5681e0d04b21e129cc'
      ) do |actual, expected|
        expect(actual.hash).to eq(expected.hash)
        expect(actual.contract).to eq(expected.contract)
      end
    end
  end

  describe '.find_by_public_key' do
    context 'my mode' do
      it 'models' do
        public_key = '02d3c80335a8ccb2ed364c06875f32240f36f7edb37d80f8dbe321b4c364b6e997'

        data = Lighstorm::Controllers::Node::FindByPublicKey.data(public_key) do |fetch|
          VCR.tape.replay("Controllers::Node.find_by_public_key/#{public_key}") { fetch.call }
        end

        node = described_class.new(data)

        expect(node._key.size).to eq(64)
        expect(node.myself?).to be(true)
        expect(node.alias).to eq('icebaker/old-stone')
        expect(node.public_key).to eq('02d3c80335a8ccb2ed364c06875f32240f36f7edb37d80f8dbe321b4c364b6e997')
        expect(node.color).to eq('#ff338f')
        expect(node.platform.blockchain).to eq('bitcoin')
        expect(node.platform.network).to eq('mainnet')
        expect(node.platform.lightning.implementation).to eq('lnd')
        expect(node.platform.lightning.version).to eq('0.15.5-beta commit=v0.15.5-beta')

        Contract.expect(
          node.to_h, 'f7aee5d6bfb0f7a90e9658a4dcab3414c2d1689d1dfbaf5681e0d04b21e129cc'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)
        end
      end
    end

    context 'other node' do
      it 'models' do
        public_key = '02003e8f41444fbddbfce965eaeb45b362b5c1b0e52b16cc249807ba7f78877928'

        data = Lighstorm::Controllers::Node::FindByPublicKey.data(public_key) do |fetch|
          VCR.tape.replay("Controllers::Node.find_by_public_key/#{public_key}") { fetch.call }
        end

        node = described_class.new(data)

        expect(node._key.size).to eq(64)
        expect(node.myself?).to be(false)
        expect(node.alias).to eq('')
        expect(node.public_key).to eq('02003e8f41444fbddbfce965eaeb45b362b5c1b0e52b16cc249807ba7f78877928')
        expect(node.color).to eq('#000000')
        expect(node.platform.blockchain).to eq('bitcoin')
        expect(node.platform.network).to eq('mainnet')

        expect { node.platform.lightning }.to raise_error(
          NotYourNodeError
        )

        Contract.expect(
          node.to_h, 'b50a6234a2b3ca7838e5f7d3d455a2ab191c5ab07202ec195d89f3b5feac2a48'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)
        end
      end
    end
  end

  describe '.all' do
    context 'samples' do
      it 'models' do
        myself = Lighstorm::Controllers::Node::Myself.data do |fetch|
          VCR.tape.replay('Controllers::Node.myself') { fetch.call }
        end

        data = Lighstorm::Controllers::Node::All.data do |fetch|
          VCR.tape.replay('Controllers::Node.all/samples') do
            data = fetch.call

            data[:describe_graph] = [
              data[:describe_graph].find { |n| n.alias != '' && n.pub_key != myself[:public_key] },
              data[:describe_graph].find { |n| n.alias == '' && n.pub_key != myself[:public_key] },
              data[:describe_graph].find { |n| n.pub_key == myself[:public_key] }
            ].map(&:to_h)

            data
          end
        end

        node_alias = described_class.new(data[0])
        node_no_alias = described_class.new(data[1])
        node_myself = described_class.new(data[2])

        expect(node_alias._key.size).to eq(64)
        expect(node_alias.myself?).to be(false)
        expect(node_alias.alias).to eq('Zero')
        expect(node_alias.public_key).to eq('0200000000009482fa1bd99ec1d71a06ebfe27e8aee305e46bb53b78c7c6ab5b2a')
        expect(node_alias.color).to eq('#000000')
        expect(node_alias.platform.blockchain).to eq('bitcoin')
        expect(node_alias.platform.network).to eq('mainnet')

        expect { node_alias.platform.lightning }.to raise_error(
          NotYourNodeError
        )

        Contract.expect(
          node_alias.to_h, 'b50a6234a2b3ca7838e5f7d3d455a2ab191c5ab07202ec195d89f3b5feac2a48'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)
        end

        expect(node_no_alias._key.size).to eq(64)
        expect(node_no_alias.myself?).to be(false)
        expect(node_no_alias.alias).to eq('')
        expect(node_no_alias.public_key).to eq('02003e8f41444fbddbfce965eaeb45b362b5c1b0e52b16cc249807ba7f78877928')
        expect(node_no_alias.color).to eq('#000000')
        expect(node_no_alias.platform.blockchain).to eq('bitcoin')
        expect(node_no_alias.platform.network).to eq('mainnet')

        expect { node_no_alias.platform.lightning }.to raise_error(
          NotYourNodeError
        )

        Contract.expect(
          node_no_alias.to_h, 'b50a6234a2b3ca7838e5f7d3d455a2ab191c5ab07202ec195d89f3b5feac2a48'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)
        end

        expect(node_myself._key.size).to eq(64)
        expect(node_myself.myself?).to be(true)
        expect(node_myself.alias).to eq('icebaker/old-stone')
        expect(node_myself.public_key).to eq('02d3c80335a8ccb2ed364c06875f32240f36f7edb37d80f8dbe321b4c364b6e997')
        expect(node_myself.color).to eq('#ff338f')
        expect(node_myself.platform.blockchain).to eq('bitcoin')
        expect(node_myself.platform.network).to eq('mainnet')
        expect(node_myself.platform.lightning.implementation).to eq('lnd')
        expect(node_myself.platform.lightning.version).to eq('0.15.5-beta commit=v0.15.5-beta')

        Contract.expect(
          node_myself.to_h, 'f7aee5d6bfb0f7a90e9658a4dcab3414c2d1689d1dfbaf5681e0d04b21e129cc'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)
        end
      end
    end
  end
end
