# frozen_string_literal: true

require 'json'

require_relative '../../../controllers/bitcoin/transaction'
require_relative '../../../controllers/bitcoin/transaction/all'

require_relative '../../../models/bitcoin/transaction'

require_relative '../../../ports/dsl/lighstorm/errors'

RSpec.describe Lighstorm::Model::Bitcoin::Transaction do
  describe 'all' do
    context 'all' do
      it 'models' do
        data = Lighstorm::Controller::Bitcoin::Transaction::All.data(
          Lighstorm::Controller::Bitcoin::Transaction.components,
          limit: 3
        ) do |fetch|
          VCR.tape.unsafe('I_KNOW_WHAT_I_AM_DOING').replay('Controller::Bitcoin::Transaction.all', limit: 3) do
            fetch.call
          end
        end

        first = described_class.new(data[0])

        expect(first._key.size).to eq(64)
        expect(first.at.utc.to_s).to eq('2023-04-02 10:21:34 UTC')
        expect(first.amount.millisatoshis).to eq(-500_000_000)
        expect(first.fee.millisatoshis).to eq(154_000)
        expect(first.hash.size).to eq(64)
        expect(first.description).to eq('Wallet Withdrawal')

        second = described_class.new(data[2])

        expect(second._key.size).to eq(64)
        expect(second.at.utc.to_s).to eq('2023-04-01 23:30:52 UTC')
        expect(second.amount.millisatoshis).to eq(1_000_000_000)
        expect(second.fee.millisatoshis).to eq(0)
        expect(second.hash.size).to eq(64)
        expect(second.description).to be_nil
      end
    end
  end
end
