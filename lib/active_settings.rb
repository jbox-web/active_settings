# frozen_string_literal: true

require 'erb'
require 'json'
require 'yaml'
require 'ostruct'
require 'singleton'

require 'deep_merge'
require 'dry-schema'
require 'active_support/core_ext/module/attribute_accessors'

require 'zeitwerk'
loader = Zeitwerk::Loader.for_gem
loader.setup

module ActiveSettings

  # ActiveSettings options
  mattr_accessor :fail_on_missing, :use_env, :env_separator, :env_prefix, :env_converter, :env_parse_values

  @@fail_on_missing  = false
  @@use_env          = false
  @@env_separator    = '.'
  @@env_prefix       = 'SETTINGS'
  @@env_converter    = :downcase
  @@env_parse_values = true

  # deep_merge options
  mattr_accessor :knockout_prefix, :merge_nil_values, :overwrite_arrays, :keep_array_duplicates

  @@knockout_prefix       = nil
  @@overwrite_arrays      = false
  @@merge_nil_values      = true
  @@keep_array_duplicates = true
end
