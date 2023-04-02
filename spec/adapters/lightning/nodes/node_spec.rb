# frozen_string_literal: true

require 'json'

require_relative '../../../../adapters/lightning/nodes/node'
require_relative '../../../../ports/grpc'

RSpec.describe Lighstorm::Adapter::Lightning::Node do
  context 'get_info' do
    it 'adapts' do
      raw = VCR.tape.replay('lightning.get_info') do
        Lighstorm::Ports::GRPC.lightning.get_info.to_h
      end

      Contract.expect(
        raw,
        '6b8477fac3a9495850e1e0e059547b205097cdca359b022c273a29455824c1ef'
      ) do |actual, expected|
        expect(actual.hash).to eq(expected.hash)
        expect(actual.contract).to eq(expected.contract)
      end

      adapted = described_class.get_info(raw)

      expect(adapted).to eq(
        { _source: :get_info,
          _key: '32564df7a5aa5e3fbef3056c77ba6531362478a80c12b0fa32c63f6bd02fde78',
          public_key: '02d3c80335a8ccb2ed364c06875f32240f36f7edb37d80f8dbe321b4c364b6e997',
          alias: 'icebaker/old-stone',
          color: '#ff338f',
          platform: { blockchain: 'bitcoin', network: 'mainnet',
                      lightning: { implementation: 'lnd', version: '0.15.5-beta commit=v0.15.5-beta' } } }
      )
    end
  end

  context 'get_node_info' do
    context 'my node' do
      it 'adapts' do
        public_key = '02d3c80335a8ccb2ed364c06875f32240f36f7edb37d80f8dbe321b4c364b6e997'

        raw = VCR.tape.replay('lightning.get_node_info', pub_key: public_key) do
          Lighstorm::Ports::GRPC.lightning.get_node_info(pub_key: public_key).to_h
        end

        Contract.expect(
          raw,
          '0e519d0a4a3f42868dd07c4d0eef3f6101fe19836e33123d8f988f938c4bc2e4'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)
          expect(actual.contract).to eq(expected.contract)
        end

        adapted = described_class.get_node_info(raw)

        expect(adapted).to eq(
          { _source: :get_node_info,
            _key: '32564df7a5aa5e3fbef3056c77ba6531362478a80c12b0fa32c63f6bd02fde78',
            public_key: '02d3c80335a8ccb2ed364c06875f32240f36f7edb37d80f8dbe321b4c364b6e997',
            alias: 'icebaker/old-stone',
            color: '#ff338f' }
        )
      end
    end

    context 'other node' do
      it 'adapts' do
        public_key = '02003e8f41444fbddbfce965eaeb45b362b5c1b0e52b16cc249807ba7f78877928'

        raw = VCR.tape.replay('lightning.get_node_info', pub_key: public_key) do
          Lighstorm::Ports::GRPC.lightning.get_node_info(pub_key: public_key).to_h
        end

        Contract.expect(
          raw,
          'd8d8feb2cd43f32ff28b62d3f54c615195948ba8294650c601f55f5d330ec2ba'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)

          expect(actual.contract).to eq(
            { channels: [],
              node: { addresses: [],
                      alias: 'String:0..10',
                      color: 'String:0..10',
                      custom_records: {},
                      features: {},
                      last_update: 'Integer:0..10',
                      pub_key: 'String:50+' },
              num_channels: 'Integer:0..10',
              total_capacity: 'Integer:0..10' }
          )
        end

        adapted = described_class.get_node_info(raw)

        expect(adapted).to eq(
          { _source: :get_node_info,
            _key: 'da4009ea916d397ae979705ca0876325c992835b45b87644ba24cd34e195fb14',
            public_key: '02003e8f41444fbddbfce965eaeb45b362b5c1b0e52b16cc249807ba7f78877928',
            alias: '',
            color: '#000000' }
        )
      end
    end
  end

  context 'describe_graph' do
    context 'with alias' do
      it 'adapts' do
        raw = VCR.tape.replay('lightning.describe_graph.nodes.with-alias') do
          Lighstorm::Ports::GRPC.lightning.describe_graph.nodes.find do |node|
            node.alias != ''
          end.to_h
        end

        Contract.expect(
          raw,
          '1d49c765e783b1a6d9e671b6774f4e5c24e07fb47b127c36fbf12f90eed33f3f'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)

          expect(actual.contract).to eq(expected.contract)
        end

        adapted = described_class.describe_graph(raw)

        expect(adapted).to eq(
          { _source: :describe_graph,
            _key: '2075df53e2c799228a5f89fe0b04382b4cb64cd218d75900a0dd5c69f64ad3b6',
            public_key: '0200000000a3eff613189ca6c4070c89206ad658e286751eca1f29262948247a5f',
            alias: 'pay.lnrouter.app',
            color: '#f8fbff' }
        )
      end
    end

    context 'no alias' do
      it 'adapts' do
        raw = VCR.tape.replay('lightning.describe_graph.nodes.no-alias') do
          Lighstorm::Ports::GRPC.lightning.describe_graph.nodes.find do |node|
            node.alias == ''
          end.to_h
        end

        Contract.expect(
          raw,
          '5287efc05a4b1851f078f30162dcf141e5f08ce8fab3696cab14db86e9d60fe3'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)

          expect(actual.contract).to eq(
            { addresses: [],
              alias: 'String:0..10',
              color: 'String:0..10',
              custom_records: {},
              features: {},
              last_update: 'Integer:0..10',
              pub_key: 'String:50+' }
          )
        end

        adapted = described_class.describe_graph(raw)

        expect(adapted).to eq(
          { _source: :describe_graph,
            _key: 'da4009ea916d397ae979705ca0876325c992835b45b87644ba24cd34e195fb14',
            alias: '',
            public_key: '02003e8f41444fbddbfce965eaeb45b362b5c1b0e52b16cc249807ba7f78877928',
            color: '#000000' }
        )
      end
    end
  end

  context 'subscribe_channel_graph' do
    it 'adapts' do
      raw = JSON.parse(TestData.read('spec/data/gossip/node/sample-a.json'))

      Contract.expect(
        raw,
        '4c2391f8606f0b8da3c846fe510dd1202a9cfd9df5f7523583c54b55c1026a5b'
      ) do |actual, expected|
        expect(actual.hash).to eq(expected.hash)
        expect(actual.contract).to eq(expected.contract)
      end

      adapted = described_class.subscribe_channel_graph(raw)

      expect(adapted).to eq(
        { _source: :subscribe_channel_graph,
          _key: 'fbce6d195972b53499122086de9b05244cef69393d8cb5d7402c2c60df736c1f',
          public_key: '02dc08e2bf7d833afd7b8dc0f8f4afd7cd64e12eb4683c8e7be95fdc13269942d6',
          alias: 'SampleNode',
          color: '#ff5002' }
      )
    end
  end
end
