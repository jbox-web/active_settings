# frozen_string_literal: true

# Borrowed from [config gem](https://github.com/rubyconfig/config)
# See: https://github.com/rubyconfig/config/blob/master/lib/config/options.rb

module ActiveSettings
  class Config < OpenStruct

    class << self
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
      # rubocop:enable Metrics/MethodLength

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

      # Recursively converts Hashes to Options (including Hashes inside Arrays)
      # rubocop:disable Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/AbcSize
      def convert_hash(hash)
        settings = ActiveSettings::Config.new

        hash.each do |key, value|
          key = key.to_s if !key.respond_to?(:to_sym) && key.respond_to?(:to_s)

          new_val =
            case value
            when Hash
              value['type'] == 'hash' ? value['contents'] : convert_hash(value)
            when Array
              value.collect { |e| e.instance_of?(Hash) ? convert_hash(e) : e }
            else
              value
            end

          settings[key] = new_val
        end

        settings
      end
      # rubocop:enable Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/AbcSize

      def deep_merge!(current, other)
        options = {
          preserve_unmergeables: false,
          knockout_prefix:       ActiveSettings.knockout_prefix,
          overwrite_arrays:      ActiveSettings.overwrite_arrays,
          merge_nil_values:      ActiveSettings.merge_nil_values,
          keep_array_duplicates: ActiveSettings.keep_array_duplicates
        }
        DeepMerge.deep_merge!(other, current, options)
      end
    end

    delegate :each, :each_key, :each_value, :collect, :keys, :empty?, to: :marshal_dump


    def key?(key)
      self[key] ? true : false
    end


    def fetch(key, default = nil)
      return self[key] if key?(key)

      if block_given?
        yield
      else
        default
      end
    end


    def to_hash
      self.class.traverse_config(self)
    end

    alias :to_h :to_hash


    def to_json(*args)
      to_hash.to_json(*args)
    end


    def merge!(other)
      current = to_hash
      other = other.dup
      self.class.deep_merge!(current, other)
      marshal_load(self.class.convert_hash(current).marshal_dump)
      self
    end


    def method_missing(method_name, *args)
      if ActiveSettings.fail_on_missing && method_name !~ /.*(?==\z)/m
        raise KeyError, "key not found: #{method_name.inspect}" unless key?(method_name)
      end
      super
    end


    def respond_to_missing?(method_name, include_private = false)
      key?(method_name) || super
    end

  end
end
