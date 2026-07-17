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

    # Same as `to_hash` but leaves Procs untouched instead of calling them.
    # Used by Config#merge! to avoid evaluating lazy values.
    def to_raw_hash(config)
      traverse_config(config, evaluate_procs: false)
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
            # Escape hatch: `{ 'type' => 'hash', 'contents' => {...} }` keeps the
            # raw Hash (accessible by []/dig) instead of wrapping it into a Config.
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
    # rubocop:disable Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/BlockLength
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
          existing = h[key]
          if !existing.nil? && !existing.is_a?(Hash)
            raise ActiveSettings::Error::EnvKeyConflictError,
                  "ENV variable '#{variable}' conflicts with a scalar value already set for '#{key}'"
          end

          h[key] ||= {}
        end

        last = keys.last
        if leaf[last].is_a?(Hash)
          raise ActiveSettings::Error::EnvKeyConflictError,
                "ENV variable '#{variable}' conflicts with a nested mapping already set for '#{last}'"
        end

        leaf[last] = ActiveSettings.env_parse_values ? cast_value(value) : value
      end

      hash
    end
    # rubocop:enable Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/BlockLength

    # NOTE: the file content is evaluated as ERB before being parsed as YAML,
    # so settings sources MUST be trusted (ERB executes arbitrary Ruby).
    # `aliases: true` is always supported since we require Ruby >= 3.2 (Psych 4).
    def load_yaml_file(file)
      data = YAML.load(ERB.new(File.read(file)).result, aliases: true)
      return {} if data.nil?

      unless data.is_a?(Hash)
        raise ActiveSettings::Error::InvalidSettingsFileError,
              "settings file '#{file}' must contain a YAML mapping, got #{data.class}"
      end

      data
    end

    private

    # rubocop:disable Metrics/MethodLength
    def traverse_config(hash, evaluate_procs: true)
      result = {}
      hash.each do |k, v|
        result[k] =
          if v.instance_of?(ActiveSettings::Config)
            traverse_config(v, evaluate_procs: evaluate_procs)
          elsif v.instance_of?(Array)
            traverse_array(v, evaluate_procs: evaluate_procs)
          elsif v.instance_of?(Proc)
            evaluate_procs ? v.call : v
          else
            v
          end
      end
      result
    end

    def traverse_array(array, evaluate_procs: true)
      array.map do |value|
        if value.instance_of?(ActiveSettings::Config)
          traverse_config(value, evaluate_procs: evaluate_procs)
        elsif value.instance_of?(Array)
          traverse_array(value, evaluate_procs: evaluate_procs)
        elsif value.instance_of?(Proc)
          evaluate_procs ? value.call : value
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
      array.each do |value|
        if value.instance_of?(ActiveSettings::Config)
          value.freeze
        elsif value.instance_of?(Array)
          freeze_array(value)
        end
      end
      array.freeze
    end

    BOOLEAN_MAPPING = { 'true' => true, 'false' => false }.freeze
    private_constant :BOOLEAN_MAPPING

    # Only base-10 literals are coerced, so zero-padded values keep their meaning
    # ("010" => 10, not octal 8) and hex/underscored strings stay strings.
    INTEGER_MATCHER = /\A[+-]?\d+\z/
    private_constant :INTEGER_MATCHER

    FLOAT_MATCHER = /\A[+-]?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?\z/
    private_constant :FLOAT_MATCHER

    def cast_value(val)
      BOOLEAN_MAPPING.fetch(val) { auto_type(val) }
    end

    def auto_type(val)
      case val
      when INTEGER_MATCHER then Integer(val, 10)
      when FLOAT_MATCHER   then Float(val)
      else val
      end
    end

  end
  # rubocop:enable Metrics/ClassLength
end
# rubocop:enable Metrics/ModuleLength
