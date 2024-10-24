# frozen_string_literal: true

# require ruby dependencies
require 'erb'
require 'json'
require 'yaml'
require 'ostruct'
require 'singleton'

# require external dependencies
require 'deep_merge/core'
require 'dry-schema'
require 'active_support/core_ext/module/attribute_accessors'
require 'active_support/core_ext/module/delegation'
require 'zeitwerk'

# load zeitwerk
Zeitwerk::Loader.for_gem.tap do |loader| # rubocop:disable Style/SymbolProc
  loader.setup
end

# rubocop:disable Metrics/ModuleLength
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

  # rubocop:disable Metrics/ClassLength
  class << self
    def to_hash(config)
      traverse_config(config)
    end

    def deep_freeze(config)
      freeze_config(config)
    end

    # Recursively converts Hashes to Options (including Hashes inside Arrays)
    # rubocop:disable Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/AbcSize
    def from_hash(hash)
      settings = ActiveSettings::Config.new

      hash.each do |key, value|
        key = key.to_s if !key.respond_to?(:to_sym) && key.respond_to?(:to_s)

        new_val =
          case value
          when Hash
            value['type'] == 'hash' ? value['contents'] : from_hash(value)
          when Array
            value.collect { |e| e.instance_of?(Hash) ? from_hash(e) : e }
          else
            value
          end

        settings[key] = new_val
      end

      settings
    end
    # rubocop:enable Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/AbcSize

    def deep_merge_hash!(current, other)
      options = {
        preserve_unmergeables: false,
        knockout_prefix:       ActiveSettings.knockout_prefix,
        overwrite_arrays:      ActiveSettings.overwrite_arrays,
        merge_nil_values:      ActiveSettings.merge_nil_values,
        keep_array_duplicates: ActiveSettings.keep_array_duplicates,
      }
      DeepMerge.deep_merge!(other, current, options)
    end

    # Borrowed from [config gem](https://github.com/rubyconfig/config/blob/master/lib/config/options.rb)
    # See: https://github.com/rubyconfig/config/commit/351c819f75d53aa5621a226b5957c79ac82ded11
    # rubocop:disable Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/AbcSize, Metrics/PerceivedComplexity
    def from_env(env)
      return {} unless ActiveSettings.use_env
      return {} if env.nil? || env.empty?

      raise ActiveSettings::Error::EnvPrefixNotDefinedError if ActiveSettings.env_prefix.nil?

      separator = ActiveSettings.env_separator
      prefix = ActiveSettings.env_prefix.to_s.split(separator)

      hash = {}

      env.each do |variable, value|
        keys = variable.to_s.split(separator)

        next if keys.shift(prefix.size) != prefix

        keys.map! do |key|
          case ActiveSettings.env_converter
          when :downcase
            key.downcase.to_sym
          when nil
            key.to_sym
          else
            raise "Invalid ENV variables name converter: #{ActiveSettings.env_converter}"
          end
        end

        leaf = keys[0...-1].inject(hash) do |h, key|
          h[key] ||= {}
        end

        leaf[keys.last] = ActiveSettings.env_parse_values ? cast_value(value) : value
      end

      hash
    end
    # rubocop:enable Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/AbcSize, Metrics/PerceivedComplexity

    def load_yaml_file(file)
      YAML.load(ERB.new(File.read(file)).result, aliases: true).to_hash
    rescue ArgumentError
      YAML.load(ERB.new(File.read(file)).result).to_hash
    end

    private

    # rubocop:disable Metrics/MethodLength
    def traverse_config(hash)
      result = {}
      hash.each do |k, v|
        result[k] =
          if v.instance_of?(ActiveSettings::Config)
            traverse_config(v)
          elsif v.instance_of?(Array)
            traverse_array(v)
          elsif v.instance_of?(Proc)
            v.call
          else
            v
          end
      end
      result
    end

    def traverse_array(array)
      array.map do |value|
        if value.instance_of?(ActiveSettings::Config)
          traverse_config(value)
        elsif value.instance_of?(Array)
          traverse_array(value)
        elsif value.instance_of?(Proc)
          value.call
        else
          value
        end
      end
    end
    # rubocop:enable Metrics/MethodLength

    def freeze_config(hash)
      hash.each_value do |v|
        if v.instance_of?(ActiveSettings::Config)
          v.freeze
        elsif v.instance_of?(Array)
          freeze_array(v)
        end
      end
    end

    def freeze_array(array)
      array.map do |value|
        if value.instance_of?(ActiveSettings::Config)
          value.freeze
        elsif value.instance_of?(Array)
          freeze_array(value)
        end
      end
    end

    BOOLEAN_MAPPING = { 'true' => true, 'false' => false }.freeze
    private_constant :BOOLEAN_MAPPING

    def cast_value(val)
      BOOLEAN_MAPPING.fetch(val) { auto_type(val) }
    end

    # rubocop:disable Style/RescueModifier
    def auto_type(val)
      Integer(val) rescue Float(val) rescue val
    end
    # rubocop:enable Style/RescueModifier

  end
  # rubocop:enable Metrics/ClassLength
end
# rubocop:enable Metrics/ModuleLength
