# frozen_string_literal: true

require 'json'

require_relative '../../../controllers/wallet/activity'
require_relative '../../../controllers/wallet/activity/all'

require_relative '../../../models/wallet/activity'

require_relative '../../../ports/dsl/lighstorm/errors'

RSpec.describe Lighstorm::Model::Wallet::Activity do
  describe 'all' do
    context 'all' do
      it 'models' do
        data = Lighstorm::Controller::Wallet::Activity::All.data(
          Lighstorm::Controller::Wallet::Activity.components,
          limit: 1
        ) do |fetch|
          VCR.tape.replay('Controller::Wallet::Activity.all', limit: 1) do
            fetch.call
          end
        end

        activity = described_class.new(data[0])

        expect(activity.at.utc.to_s).to eq('2023-04-02 12:48:33 UTC')
        expect(activity.direction).to eq('in')
        expect(activity.how).to eq('with-invoice')
        expect(activity.invoice.class.to_s).to eq('Lighstorm::Model::Lightning::Invoice')
        expect(activity.message).to eq('1k going')
      end
    end
  end
end
