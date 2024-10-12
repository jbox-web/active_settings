# frozen_string_literal: true

require_relative 'lib/active_settings/version'

Gem::Specification.new do |s|
  s.name        = 'active_settings'
  s.version     = ActiveSettings::VERSION::STRING
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Nicolas Rodriguez']
  s.email       = ['nico@nicoladmin.fr']
  s.homepage    = 'https://github.com/jbox-web/active_settings'
  s.summary     = 'A gem to manage Settings'
  s.license     = 'MIT'
  s.metadata    = {
    'homepage_uri'    => 'https://github.com/jbox-web/active_settings',
    'changelog_uri'   => 'https://github.com/jbox-web/active_settings/blob/master/CHANGELOG.md',
    'source_code_uri' => 'https://github.com/jbox-web/active_settings',
    'bug_tracker_uri' => 'https://github.com/jbox-web/active_settings/issues',
  }

  s.required_ruby_version = '>= 3.0.0'

  s.files = Dir['README.md', 'CHANGELOG.md', 'LICENSE', 'lib/**/*.rb']

  s.add_dependency 'activesupport', '>= 7.0'
  s.add_dependency 'deep_merge',    '~> 1.2.1'
  s.add_dependency 'dry-schema',    '>= 1.2.0'
  s.add_dependency 'zeitwerk'
end
