# frozen_string_literal: true

RSpec.describe Sanitizer do
  describe 'obfuscate' do
    context 'bytes' do
      let(:value) { ['lorem'].pack('H*') }

      it 'obfuscates' do
        expect(value.encoding.name).to eq('ASCII-8BIT')
        expect(described_class.obfuscate(value).encoding.name).to eq('ASCII-8BIT')
        expect(described_class.obfuscate(value)).not_to eq(value)
        expect(described_class.obfuscate(value).class).to eq(value.class)
        expect(described_class.obfuscate(value).size).to eq(value.size)
      end
    end

    context 'string' do
      let(:value) { 'lorem' }

      it 'obfuscates' do
        expect(described_class.obfuscate(value)).not_to eq(value)
        expect(described_class.obfuscate(value).class).to eq(value.class)
        expect(described_class.obfuscate(value).size).to eq(value.size)
      end
    end

    context 'symbol' do
      let(:value) { :symbol }

      it 'obfuscates' do
        expect(described_class.obfuscate(value)).not_to eq(value)
        expect(described_class.obfuscate(value).class).to eq(value.class)
        expect(described_class.obfuscate(value).size).to eq(value.size)
      end
    end

    context 'integer' do
      let(:value) { 127 }

      it 'obfuscates' do
        expect(described_class.obfuscate(value)).not_to eq(value)
        expect(described_class.obfuscate(value).class).to eq(value.class)
        expect(described_class.obfuscate(value).to_s.size).to eq(value.to_s.size)
      end
    end

    context 'integer B' do
      let(:value) { 0 }

      it 'obfuscates' do
        expect(described_class.obfuscate(value)).not_to eq(value)
        expect(described_class.obfuscate(value).class).to eq(value.class)
        expect(described_class.obfuscate(value).to_s.size).to eq(value.to_s.size)
      end
    end

    context 'float' do
      let(:value) { 8723.2324 }

      it 'obfuscates' do
        expect(described_class.obfuscate(value)).not_to eq(value)
        expect(described_class.obfuscate(value).class).to eq(value.class)
        expect(described_class.obfuscate(value).to_s.size).to eq(value.to_s.size)
      end
    end

    context 'float b' do
      let(:value) { 1.to_f }

      it 'obfuscates' do
        expect(described_class.obfuscate(value)).not_to eq(value)
        expect(described_class.obfuscate(value).class).to eq(value.class)
        expect(described_class.obfuscate(value).to_s.size).to eq(value.to_s.size)
      end
    end
  end

  describe 'build_paths' do
    it 'builds all paths' do
      data = {
        value_msat: 982_342_000,
        r_preimage: ['lorem'].pack('H*'),
        a: [b: 'e']
      }

      paths = described_class.build_paths(data)

      expect(paths).to eq(['value_msat', 'r_preimage', 'b <= a'])
    end
  end

  describe 'path_to_key' do
    context 'scenario A' do
      it 'path to key' do
        key = described_class.path_to_key(
          [
            'mine', 'list_channels', 2, 'remote_constraints', 'min_htlc_msat'
          ]
        )

        expect(key).to eq('min_htlc_msat <= remote_constraints')
      end
    end

    context 'scenario B' do
      it 'path to key' do
        key = described_class.path_to_key(
          [:lookup_invoice,
           '402be5ba65c4f28288ae52f83a929542224266118cecc182b2cc139249107f0a',
           :htlcs,
           '[]',
           :custom_records,
           5_482_373_484]
        )

        expect(key).to eq('custom_records <= htlcs')
      end
    end

    context 'scenario C' do
      it 'path to key' do
        key = described_class.path_to_key(
          %i[local_constraints max_pending_amt_msat]
        )

        expect(key).to eq('max_pending_amt_msat <= local_constraints')
      end
    end

    context 'scenario D' do
      it 'path to key' do
        key = described_class.path_to_key(
          [:get_node_info, '026165850492521f4ac8abd9bd8088123446d126f648ca35e60f88177dc149ceb2', :num_channels]
        )

        expect(key).to eq('num_channels <= get_node_info')
      end
    end
  end

  describe 'protect' do
    it 'protect dangerous data' do
      data = {
        value_msat: 982_342_000,
        r_preimage: ['lorem'].pack('H*')
      }

      protected_data = described_class.protect(data)

      expect(protected_data[:value_msat]).to eq(data[:value_msat])

      expect(protected_data[:r_preimage].unpack1('H*').size).to eq(6)

      expect(protected_data[:r_preimage]).not_to eq(data[:r_preimage])
    end
  end
end
