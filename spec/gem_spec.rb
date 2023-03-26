# frozen_string_literal: true

RSpec.describe 'Gemspec' do
  let(:gemfile) { File.read('Gemfile') }
  let(:gemspec) { File.read('lighstorm.gemspec') }

  it 'ensures that no local path gems are being used' do
    if gemfile =~ /\.\./ || gemfile =~ /path/
      expect { raise "local path gems not allowed, but found at 'Gemfile'" }.not_to raise_error
    end

    if gemspec =~ /\.\./ || gemspec =~ /add_dependency.*path/
      expect { raise "local path gems not allowed, but found at 'lighstorm.gemspec'" }.not_to raise_error
    end
  end
end
