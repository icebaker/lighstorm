# frozen_string_literal: true

require 'json'

require_relative '../../controllers/activity'
require_relative '../../controllers/activity/all'

require_relative '../../models/activity'

require_relative '../../ports/dsl/lighstorm/errors'

RSpec.describe Lighstorm::Models::Activity do
  describe 'all' do
    context 'all' do
      it 'models' do
        data = Lighstorm::Controllers::Activity::All.data(
          Lighstorm::Controllers::Activity.components,
          limit: 1
        ) do |fetch|
          VCR.tape.replay('Controllers::Activity.all', limit: 1) do
            fetch.call
          end
        end

        activity = described_class.new(data[0])

        expect(activity.at.utc.to_s).to eq('2023-03-13 09:45:09 UTC')
        expect(activity.direction).to eq('in')
        expect(activity.how).to eq('forwarding')
        expect(activity.invoice).to be_nil
        expect(activity.message).to be_nil
      end
    end
  end
end
