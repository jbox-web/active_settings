# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.push(lib) unless $LOAD_PATH.include?(lib)
require 'active-settings/version'

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

  s.add_dependency 'activesupport',  '>= 4.2'
  s.add_dependency 'deep_merge',     '~> 1.2.1'
  s.add_dependency 'dry-validation', '>= 0.10.4'

  s.add_development_dependency 'appraisal'
  s.add_development_dependency 'pry'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'simplecov'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_paths = ['lib']
end
