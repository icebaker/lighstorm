# frozen_string_literal: true

require 'json'

require_relative '../../controllers/transaction/all'

require_relative '../../models/transaction'

require_relative '../../ports/dsl/lighstorm/errors'

RSpec.describe Lighstorm::Models::Transaction do
  describe 'all' do
    context 'all' do
      it 'models' do
        data = Lighstorm::Controllers::Transaction::All.data(limit: 1) do |fetch|
          VCR.tape.replay('Controllers::Transaction.all', limit: 1) do
            fetch.call
          end
        end

        transaction = described_class.new(data[0])

        expect(transaction.at.utc.to_s).to eq('2023-03-10 22:41:09 UTC')
        expect(transaction.direction).to eq('in')
        expect(transaction.message).to be_nil
        expect(transaction.invoice.amount.millisatoshis).to eq(1000)
      end
    end
  end
end
