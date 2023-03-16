# frozen_string_literal: true

require_relative '../../../ports/dsl/lighstorm'

RSpec.describe 'DSL' do
  it 'provides expected methods' do
    expect(Lighstorm.version).to eq('0.0.13')
    expect(Lighstorm).to respond_to(:connect!, :inject_middleware!)

    expect(Lighstorm::Node).to respond_to(:myself, :all, :find_by_public_key)
    expect(Lighstorm::Channel).to respond_to(:mine, :all, :find_by_id)
    expect(Lighstorm::Forward).to respond_to(:all, :first, :last, :group_by_channel)
    expect(Lighstorm::Payment).to respond_to(:all, :first, :last)
    expect(Lighstorm::Invoice).to respond_to(:all, :find_by_secret_hash, :create, :decode)
    expect(Lighstorm::Satoshis).to respond_to(:new)
  end
end
