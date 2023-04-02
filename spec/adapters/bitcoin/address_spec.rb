# frozen_string_literal: true

require 'json'

require_relative '../../../adapters/bitcoin/address'
require_relative '../../../ports/grpc'

RSpec.describe Lighstorm::Adapter::Bitcoin::Address do
  context 'new_address' do
    it 'adapts' do
      raw = VCR.tape.replay('lightning.new_address') do
        Lighstorm::Ports::GRPC.lightning.new_address.to_h
      end

      Contract.expect(
        raw,
        'fbae2e7ae4540478b03134acdad775ae17df5f46673edf00dd4a860f639e894b'
      ) do |actual, expected|
        expect(actual.hash).to eq(expected.hash)
        expect(actual.contract).to eq(expected.contract)
      end

      adapted = described_class.new_address(raw)

      Contract.expect(
        adapted,
        '7c1b2bddc172356a77b17ff0a2c8158a169e5caafa94df42f795cc4689f72e2e'
      ) do |actual, expected|
        expect(actual.hash).to eq(expected.hash)
        expect(actual.contract).to eq(expected.contract)
      end
    end
  end
end
