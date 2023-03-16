# frozen_string_literal: true

require_relative 'static/spec'

Gem::Specification.new do |spec|
  spec.name    = Lighstorm::Static::SPEC[:name]
  spec.version = Lighstorm::Static::SPEC[:version]
  spec.authors = [Lighstorm::Static::SPEC[:author]]

  spec.summary = Lighstorm::Static::SPEC[:summary]
  spec.description = Lighstorm::Static::SPEC[:description]

  spec.homepage = Lighstorm::Static::SPEC[:documentation]

  spec.license = Lighstorm::Static::SPEC[:license]

  spec.required_ruby_version = Gem::Requirement.new('>= 3.0.0')

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = Lighstorm::Static::SPEC[:github]
  spec.metadata['documentation_uri'] = Lighstorm::Static::SPEC[:documentation]
  spec.metadata['bug_tracker_uri'] = Lighstorm::Static::SPEC[:issues]

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      f.match(%r{\A(?:test|spec|features)/})
    end
  end

  spec.require_paths = ['ports/dsl']

  spec.add_dependency 'dotenv', '~> 2.8', '>= 2.8.1'
  spec.add_dependency 'lnd-client', '~> 0.0.6'
  spec.add_dependency 'zache', '~> 0.12.0'

  spec.metadata['rubygems_mfa_required'] = 'true'
end
