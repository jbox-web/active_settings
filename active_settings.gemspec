# frozen_string_literal: true

require_relative 'lib/active_settings/version'

Gem::Specification.new do |s|
  s.name        = 'active_settings'
  s.version     = ActiveSettings::VERSION::STRING
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Nicolas Rodriguez']
  s.email       = ['nicoladmin@free.fr']
  s.homepage    = 'https://github.com/jbox-web/active_settings'
  s.summary     = 'A gem to manage Settings'
  s.license     = 'MIT'
  s.metadata    = {
    'homepage_uri'    => 'https://github.com/jbox-web/active_settings',
    'changelog_uri'   => 'https://github.com/jbox-web/active_settings/blob/master/CHANGELOG.md',
    'source_code_uri' => 'https://github.com/jbox-web/active_settings',
    'bug_tracker_uri' => 'https://github.com/jbox-web/active_settings/issues'
  }

  s.required_ruby_version = '>= 2.6.0'

  s.files = `git ls-files`.split("\n")

  s.add_runtime_dependency 'activesupport', '>= 5.1'
  s.add_runtime_dependency 'deep_merge',    '~> 1.2.1'
  s.add_runtime_dependency 'dry-schema',    '>= 1.2.0'
  s.add_runtime_dependency 'zeitwerk'

  s.add_development_dependency 'appraisal'
  s.add_development_dependency 'guard-rspec'
  s.add_development_dependency 'pry'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rubocop'
  s.add_development_dependency 'rubocop-rake'
  s.add_development_dependency 'rubocop-rspec'
  s.add_development_dependency 'simplecov'
end
