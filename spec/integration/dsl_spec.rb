# frozen_string_literal: true

require_relative '../../ports/dsl/lighstorm'
require_relative '../../ports/dsl/lighstorm/errors'

require_relative '../../models/invoice'

RSpec.describe 'Integration Tests' do
  context 'DSL' do
    it 'works as expected' do
      expect(Lighstorm.version).to eq('0.0.14')

      expect(LighstormError.new('some error').message).to be('some error')
    end
  end

  context 'TODO' do
    it 'raises TODOError' do
      expect { Lighstorm::Models::Invoice.new({}, {}).pay(route: []) }.to raise_error(
        ToDoError, 'Lighstorm::Controllers::Invoice::PayThroughRoute'
      )
    end
  end
end
