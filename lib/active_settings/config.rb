# frozen_string_literal: true

module ActiveSettings
  class Config < OpenStruct

    def each(*args, &block)
      marshal_dump.each(*args, &block)
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


    # rubocop:disable Metrics/MethodLength
    def to_hash
      result = {}
      each do |k, v|
        result[k] =
          if v.instance_of?(ActiveSettings::Config)
            v.to_hash
          elsif v.instance_of?(Array)
            descend_array(v)
          elsif v.instance_of?(Proc)
            v.call
          else
            v
          end
      end
      result
    end
    # rubocop:enable Metrics/MethodLength


    def to_json(*args)
      to_hash.to_json(*args)
    end


    def merge!(hash)
      options = {
        preserve_unmergeables: false,
        knockout_prefix:       ActiveSettings.knockout_prefix,
        overwrite_arrays:      ActiveSettings.overwrite_arrays,
        merge_nil_values:      ActiveSettings.merge_nil_values,
        keep_array_duplicates: ActiveSettings.keep_array_duplicates
      }

      current = to_hash
      DeepMerge.deep_merge!(hash.dup, current, options)
      marshal_load(__convert(current).marshal_dump)
      self
    end


    private


    def method_missing(method_name, *args)
      if ActiveSettings.fail_on_missing && method_name !~ /.*(?==\z)/m
        raise KeyError, "key not found: #{method_name.inspect}" unless key?(method_name)
      end
      super
    end


    def descend_array(array)
      array.map do |value|
        if value.instance_of?(ActiveSettings::Config)
          value.to_hash
        elsif value.instance_of?(Array)
          descend_array(value)
        else
          value
        end
      end
    end


    # Recursively converts Hashes to Options (including Hashes inside Arrays)
    # rubocop:disable Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/AbcSize
    def __convert(hash)
      s = ActiveSettings::Config.new

      hash.each do |k, v|
        k = k.to_s if !k.respond_to?(:to_sym) && k.respond_to?(:to_s)

        if v.is_a?(Hash)
          v = v['type'] == 'hash' ? v['contents'] : __convert(v)
        elsif v.is_a?(Array)
          v = v.collect { |e| e.instance_of?(Hash) ? __convert(e) : e }
        end

        if s.respond_to?(:[]=)
          s[k] = v
        else
          s.new_ostruct_member(k)
          s.send("#{k}=".to_sym, v)
        end

      end
      s
    end
    # rubocop:enable Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/AbcSize


    BOOLEAN_MAPPING = { 'true' => true, 'false' => false }.freeze


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
end
