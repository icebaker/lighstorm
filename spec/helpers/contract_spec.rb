# frozen_string_literal: true

require 'date'

RSpec.describe Contract do
  describe 'generate' do
    it 'avoid unexpected config' do
      expect(Contract::GENERATE).to be(false)
    end
  end

  describe 'contract_type' do
    it 'generates type' do
      expect(described_class.contract_type(nil)).to eq('Nil')
      expect(described_class.contract_type(false)).to eq('Boolean')
      expect(described_class.contract_type(true)).to eq('Boolean')

      expect(described_class.contract_type(:a)).to eq('Symbol:0..10')

      expect(described_class.contract_type(DateTime.now)).to eq('DateTime')
      expect(described_class.contract_type(Time.now)).to eq('Time')

      expect(described_class.contract_type('')).to eq('String:0..10')
      expect(described_class.contract_type('a')).to eq('String:0..10')
      expect(described_class.contract_type('a' * 10)).to eq('String:0..10')

      expect(described_class.contract_type('a' * 11)).to eq('String:11..20')
      expect(described_class.contract_type('a' * 20)).to eq('String:11..20')

      expect(described_class.contract_type('a' * 21)).to eq('String:21..30')
      expect(described_class.contract_type('a' * 30)).to eq('String:21..30')

      expect(described_class.contract_type('a' * 31)).to eq('String:31..40')
      expect(described_class.contract_type('a' * 40)).to eq('String:31..40')

      expect(described_class.contract_type('a' * 41)).to eq('String:41..50')
      expect(described_class.contract_type('a' * 50)).to eq('String:41..50')

      expect(described_class.contract_type('a' * 51)).to eq('String:50+')
      expect(described_class.contract_type('a' * 120)).to eq('String:50+')

      expect(described_class.contract_type(1)).to eq('Integer:0..10')
      expect(described_class.contract_type(13)).to eq('Integer:0..10')
      expect(described_class.contract_type(13_213_123_131)).to eq('Integer:11..20')
      expect(described_class.contract_type(1.5)).to eq('Float:0..10')
      expect(described_class.contract_type(1.5123812312312)).to eq('Float:11..20')
    end
  end

  describe 'hash' do
    context 'same values' do
      it 'generates hash' do
        a = { a: 1, b: 2, c: { d: 3, e: 4 } }
        b = { b: 2, a: 1, c: { e: 4, d: 3 } }

        expect(a).to eq(b)

        expect(described_class.generate(a)).to eq(described_class.generate(b))

        expect(
          described_class.hash(described_class.generate(a), save_to_disk: false)
        ).to eq(described_class.hash(described_class.generate(b), save_to_disk: false))
      end
    end

    context 'different values, same size' do
      it 'generates hash' do
        a = { a: 1, b: 2, c: { d: 3, e: 4 } }
        b = { b: 2, a: 1, c: { e: 4, d: 1 } }

        expect(a).not_to eq(b)

        expect(described_class.generate(a)).to eq(described_class.generate(b))

        expect(
          described_class.hash(described_class.generate(a), save_to_disk: false)
        ).to eq(described_class.hash(described_class.generate(b), save_to_disk: false))
      end
    end

    context 'different values, valid different sizes' do
      it 'generates hash' do
        a = { a: 1, b: 2, c: { d: 3, e: 4 } }
        b = { b: 2, a: 1, c: { e: 4, d: 124 } }

        expect(a).not_to eq(b)

        expect(described_class.generate(a)).to eq(described_class.generate(b))

        expect(
          described_class.hash(described_class.generate(a), save_to_disk: false)
        ).to eq(described_class.hash(described_class.generate(b), save_to_disk: false))
      end
    end

    context 'different values, invalid different sizes' do
      it 'generates hash' do
        a = { a: 1, b: 2, c: { d: 124, e: 4 } }
        b = { b: 2, a: 1, c: { e: 4, d: 21_312_312_312_312 } }

        expect(a).not_to eq(b)

        expect(described_class.generate(a)).not_to eq(described_class.generate(b))

        expect(
          described_class.hash(described_class.generate(a), save_to_disk: false)
        ).not_to eq(described_class.hash(described_class.generate(b), save_to_disk: false))
      end
    end
  end
end
