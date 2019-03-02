# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)
task default: :spec

task :console do
  require 'pry'
  require 'active_settings'
  puts 'Loaded ActiveSettings'
  ARGV.clear
  Pry.start
end
