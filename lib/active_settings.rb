# frozen_string_literal: true

require 'erb'
require 'json'
require 'yaml'
require 'ostruct'
require 'singleton'

require 'deep_merge'
require 'dry-schema'
require 'active_support/core_ext/module/attribute_accessors'
require 'active_support/core_ext/module/delegation'

require 'zeitwerk'
loader = Zeitwerk::Loader.for_gem
loader.setup

module ActiveSettings
  # ActiveSettings options
  mattr_accessor :fail_on_missing,  default: false
  mattr_accessor :use_env,          default: false
  mattr_accessor :env_separator,    default: '.'
  mattr_accessor :env_prefix,       default: 'SETTINGS'
  mattr_accessor :env_converter,    default: :downcase
  mattr_accessor :env_parse_values, default: true

  # deep_merge options
  mattr_accessor :knockout_prefix,       default: nil
  mattr_accessor :merge_nil_values,      default: false
  mattr_accessor :overwrite_arrays,      default: true
  mattr_accessor :keep_array_duplicates, default: true
end
