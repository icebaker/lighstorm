# frozen_string_literal: true

require 'json'

require_relative '../../../adapters/bitcoin/transaction'
require_relative '../../../ports/grpc'

RSpec.describe Lighstorm::Adapter::Bitcoin::Transaction do
  context 'get_transactions' do
    it 'adapts' do
      raw = VCR.tape.replay('lightning.get_transactions.first') do
        Lighstorm::Ports::GRPC.lightning.get_transactions.transactions.first.to_h
      end

      Contract.expect(
        raw,
        '2a149ed13b2ad0f45711ba165e5d392d11a9cddf509cd2aeda956e7a0b734221'
      ) do |actual, expected|
        expect(actual.hash).to eq(expected.hash)
        expect(actual.contract).to eq(expected.contract)
      end

      adapted = described_class.get_transactions(raw)

      Contract.expect(
        adapted,
        'c9c432f665335fc09dac7614812f297f2fc73edfc5a5f997dcaf9527346579e0'
      ) do |actual, expected|
        expect(actual.hash).to eq(expected.hash)
        expect(actual.contract).to eq(expected.contract)
      end
    end
  end
end
