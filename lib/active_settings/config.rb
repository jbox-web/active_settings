# frozen_string_literal: true

# Borrowed from [config gem](https://github.com/rubyconfig/config)
# See: https://github.com/rubyconfig/config/blob/master/lib/config/options.rb

module ActiveSettings
  # rubocop:disable Metrics/ClassLength
  class Config < OpenStruct

    def each(*args, &block)
      marshal_dump.each(*args, &block)
    end


    def each_key(*args, &block)
      marshal_dump.each_key(*args, &block)
    end


    def each_value(*args, &block)
      marshal_dump.each_value(*args, &block)
    end


    def collect(*args, &block)
      marshal_dump.collect(*args, &block)
    end


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
      traverse_hash(self)
    end

     alias :to_h :to_hash


    def to_json(*args)
      to_hash.to_json(*args)
    end


    def merge!(hash)
      current = to_hash
      hash = hash.dup
      deep_merge!(current, hash)
      marshal_load(__convert(current).marshal_dump)
      self
    end


    def method_missing(method_name, *args)
      if ActiveSettings.fail_on_missing && method_name !~ /.*(?==\z)/m
        raise KeyError, "key not found: #{method_name.inspect}" unless key?(method_name)
      end
      super
    end


    def respond_to_missing?(*args)
      super
    end


    private


    def deep_merge!(current, hash)
      options = {
        preserve_unmergeables: false,
        knockout_prefix:       ActiveSettings.knockout_prefix,
        overwrite_arrays:      ActiveSettings.overwrite_arrays,
        merge_nil_values:      ActiveSettings.merge_nil_values,
        keep_array_duplicates: ActiveSettings.keep_array_duplicates
      }
      DeepMerge.deep_merge!(hash, current, options)
    end


    # rubocop:disable Metrics/MethodLength
    def traverse_hash(hash)
      result = {}
      hash.each do |k, v|
        result[k] =
          if v.instance_of?(ActiveSettings::Config)
            traverse_hash(v)
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
          traverse_hash(value)
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
    # rubocop:disable Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/AbcSize
    def __convert(hash)
      s = ActiveSettings::Config.new

      hash.each do |key, value|
        key = key.to_s if !key.respond_to?(:to_sym) && key.respond_to?(:to_s)

        new_val =
          case value
          when Hash
            value['type'] == 'hash' ? value['contents'] : __convert(value)
          when Array
            value.collect { |e| e.instance_of?(Hash) ? __convert(e) : e }
          else
            value
          end

        s[key] = new_val
      end
      s
    end
    # rubocop:enable Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/AbcSize


    BOOLEAN_MAPPING = { 'true' => true, 'false' => false }.freeze
    private_constant :BOOLEAN_MAPPING


    # Try to convert boolean string to a correct type
    def __value(val)
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
