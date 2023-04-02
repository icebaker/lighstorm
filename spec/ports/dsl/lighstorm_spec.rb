# frozen_string_literal: true

require_relative '../../../ports/dsl/lighstorm'
require_relative '../../../ports/dsl/lighstorm/errors'

RSpec.describe 'DSL' do
  it 'provides expected methods' do
    expect(Lighstorm.version).to eq('0.0.15')
    expect(Lighstorm).to respond_to(:connect!, :inject_middleware!)

    expect(Lighstorm::Wallet).to respond_to(:balance)
    expect(Lighstorm::Wallet::Activity).to respond_to(:all)

    expect(Lighstorm::Bitcoin::Address).to respond_to(:new, :create)
    expect(Lighstorm::Bitcoin::Transaction).to respond_to(:all, :find_by_hash)

    expect(Lighstorm::Lightning::Node).to respond_to(:myself, :all, :find_by_public_key)
    expect(Lighstorm::Lightning::Channel).to respond_to(:mine, :all, :find_by_id)
    expect(Lighstorm::Lightning::Invoice).to respond_to(:all, :find_by_secret_hash, :create, :decode)
    expect(Lighstorm::Lightning::Payment).to respond_to(:all, :first, :last)
    expect(Lighstorm::Lightning::Forward).to respond_to(:all, :first, :last, :group_by_channel)

    expect(Lighstorm::Satoshis).to respond_to(:new)
    expect(Lighstorm::Connection).to respond_to(:connect!, :all, :default, :for, :add!, :remove!)

    expect(Lighstorm::Errors::LighstormError).to respond_to(:new)
    expect(LighstormError).to respond_to(:new)
  end
end
