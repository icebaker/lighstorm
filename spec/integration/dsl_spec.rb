# frozen_string_literal: true

require_relative '../../ports/dsl/lighstorm'
require_relative '../../ports/dsl/lighstorm/errors'

require_relative '../../models/lightning/invoice'

RSpec.describe 'Integration Tests' do
  context 'DSL' do
    it 'works as expected' do
      expect(Lighstorm.version).to eq('0.0.15')

      expect(LighstormError.new('some error').message).to be('some error')
    end
  end

  context 'TODO' do
    it 'raises TODOError' do
      expect { Lighstorm::Model::Lightning::Invoice.new({}, {}).pay(route: []) }.to raise_error(
        ToDoError, 'Lighstorm::Controller::Lightning::Invoice::PayThroughRoute'
      )
    end
  end
end
