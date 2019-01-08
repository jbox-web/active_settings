# frozen_string_literal: true

require_relative 'lib/active-settings/version'

Gem::Specification.new do |s|
  s.name        = 'active-settings'
  s.version     = ActiveSettings::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Nicolas Rodriguez']
  s.email       = ['nicoladmin@free.fr']
  s.homepage    = 'https://github.com/jbox-web/active-settings'
  s.summary     = 'A gem to manage Settings'
  s.license     = 'MIT'

  s.required_ruby_version = '>= 2.3.0'

  s.files = `git ls-files`.split("\n")

  s.add_runtime_dependency 'activesupport',  '>= 4.2'
  s.add_runtime_dependency 'deep_merge',     '~> 1.2.1'
  s.add_runtime_dependency 'dry-validation', '>= 0.10.4'

  s.add_development_dependency 'appraisal'
  s.add_development_dependency 'pry'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'simplecov'
end
