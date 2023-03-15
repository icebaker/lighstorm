# frozen_string_literal: true

require 'json'

require_relative '../../controllers/transaction/all'

require_relative '../../models/transaction'

require_relative '../../ports/dsl/lighstorm/errors'

RSpec.describe Lighstorm::Models::Transaction do
  describe 'all' do
    context 'all' do
      it 'models' do
        data = Lighstorm::Controllers::Transaction::All.data(limit: 2) do |fetch|
          VCR.tape.unsafe('I_KNOW_WHAT_I_AM_DOING').replay('Controllers::Transaction.all', limit: 2) do
            fetch.call
          end
        end

        first = described_class.new(data[0])

        expect(first._key.size).to eq(64)
        expect(first.at.utc.to_s).to eq('2023-03-14 00:13:13 UTC')
        expect(first.amount.millisatoshis).to eq(-258_237_000)
        expect(first.fee.millisatoshis).to eq(8_237_000)
        expect(first.hash.size).to eq(64)
        expect(first.label).to eq('0:openchannel:shortchanid-131941395398657')

        second = described_class.new(data[1])

        expect(second._key.size).to eq(64)
        expect(second.at.utc.to_s).to eq('2023-03-14 00:13:11 UTC')
        expect(second.amount.millisatoshis).to eq(500_000_000)
        expect(second.fee.millisatoshis).to eq(0)
        expect(second.hash.size).to eq(64)
        expect(second.label).to eq('')
      end
    end
  end
end
