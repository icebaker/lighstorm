# frozen_string_literal: true

require_relative '../../../adapters/nodes/node'
require_relative '../../../ports/grpc'

RSpec.describe Lighstorm::Adapter::Node do
  context 'get_info' do
    it 'adapts' do
      raw = VCR.replay('lightning.get_info') do
        Lighstorm::Ports::GRPC.lightning.get_info.to_h
      end

      Contract.expect(
        raw,
        'e2e63846dbef75a25f112681ca5f53f8bff5201959fd0e5022216e704572e74e'
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

        raw = VCR.replay('lightning.get_node_info', pub_key: public_key) do
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

        raw = VCR.replay('lightning.get_node_info', pub_key: public_key) do
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
        raw = VCR.replay('lightning.describe_graph.nodes.with-alias') do
          Lighstorm::Ports::GRPC.lightning.describe_graph.nodes.find do |node|
            node.alias != ''
          end.to_h
        end

        Contract.expect(
          raw,
          'b533864b16e15b859d38c302e90999c33eaec0e35e80e3624e303eea091653d5'
        ) do |actual, expected|
          expect(actual.hash).to eq(expected.hash)

          expect(actual.contract).to eq(
            { addresses: [{ addr: 'String:11..20', network: 'String:0..10' }],
              alias: 'String:0..10',
              color: 'String:0..10',
              custom_records: {},
              features: {
                1 => { is_known: 'Boolean', is_required: 'Boolean', name: 'String:11..20' },
                5 => { is_known: 'Boolean', is_required: 'Boolean', name: 'String:21..30' },
                7 => { is_known: 'Boolean', is_required: 'Boolean', name: 'String:11..20' },
                8 => { is_known: 'Boolean', is_required: 'Boolean', name: 'String:0..10' },
                11 => { is_known: 'Boolean', is_required: 'Boolean', name: 'String:0..10' },
                13 => { is_known: 'Boolean', is_required: 'Boolean', name: 'String:11..20' },
                14 => { is_known: 'Boolean', is_required: 'Boolean', name: 'String:11..20' },
                17 => { is_known: 'Boolean', is_required: 'Boolean', name: 'String:11..20' },
                19 => { is_known: 'Boolean', is_required: 'Boolean', name: 'String:11..20' },
                27 => { is_known: 'Boolean', is_required: 'Boolean', name: 'String:11..20' },
                45 => { is_known: 'Boolean', is_required: 'Boolean', name: 'String:21..30' },
                47 => { is_known: 'Boolean', is_required: 'Boolean', name: 'String:0..10' },
                51 => { is_known: 'Boolean', is_required: 'Boolean', name: 'String:0..10' },
                55 => { is_known: 'Boolean', is_required: 'Boolean', name: 'String:0..10' }
              },
              last_update: 'Integer:0..10',
              pub_key: 'String:50+' }
          )
        end

        adapted = described_class.describe_graph(raw)

        expect(adapted).to eq(
          { _source: :describe_graph,
            _key: '7a924eda93e428f641237c638305ef6a7003a1fd83f87183da91b52483cd0f1e',
            public_key: '0200000000009482fa1bd99ec1d71a06ebfe27e8aee305e46bb53b78c7c6ab5b2a',
            alias: 'Zero',
            color: '#000000' }
        )
      end
    end

    context 'no alias' do
      it 'adapts' do
        raw = VCR.replay('lightning.describe_graph.nodes.no-alias') do
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
end
