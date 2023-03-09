# frozen_string_literal: true

require_relative './spec/helpers/tasks/contracts'

# rspec --format json | bundle exec rake contracts:fix
namespace :contracts do
  desc 'Fix Contract Tests Hash'
  task :fix do
    Tasks::Contracts.fix($stdin.gets)
  end
end
