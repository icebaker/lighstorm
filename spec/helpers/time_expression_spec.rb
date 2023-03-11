# frozen_string_literal: true

require 'json'

require_relative '../../helpers/time_expression'
require_relative '../../models/errors'

RSpec.describe Lighstorm::Helpers::TimeExpression do
  context 'seconds' do
    it 'raises errors' do
      expect do
        expect(described_class.seconds(5))
      end.to raise_error Lighstorm::Errors::ArgumentError, 'missing keywords for time expression'

      expect do
        expect(described_class.seconds({}))
      end.to raise_error Lighstorm::Errors::ArgumentError, 'missing keywords for time expression'

      expect do
        expect(described_class.seconds({ centuries: 1 }))
      end.to raise_error(
        Lighstorm::Errors::ArgumentError,
        'unexpected keyword :centuries for time expression {:centuries=>1}'
      )
    end

    it 'converts to seconds' do
      expect(described_class.seconds({ seconds: 5 })).to eq(5)
      expect(described_class.seconds({ minutes: 1 })).to eq(60)
      expect(described_class.seconds({ hours: 1 })).to eq(3600)
      expect(described_class.seconds({ minutes: 1, seconds: 30 })).to eq(90)
      expect(described_class.seconds({ days: 1 })).to eq(86_400)
    end
  end
end
