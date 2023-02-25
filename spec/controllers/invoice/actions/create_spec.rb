# frozen_string_literal: true

require_relative '../../../../controllers/invoice/actions/create'
require_relative '../../../../models/satoshis'
require_relative '../../../../ports/dsl/lighstorm/errors'

RSpec.describe Lighstorm::Controllers::Invoice::Create do
  describe 'create invoice' do
    it 'previews' do
      preview = described_class.perform(
        milisatoshis: 1_000, description: 'lorem', preview: true
      )

      expect(preview).to eq(
        { service: :lightning,
          method: :add_invoice,
          params: { memo: 'lorem', value_msat: 1000 } }
      )
    end
  end
end
