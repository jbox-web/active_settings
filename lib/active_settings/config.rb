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


    def to_hash
      result = {}
      marshal_dump.each do |k, v|
        if v.instance_of?(ActiveSettings::Config)
          result[k] = v.to_hash
        elsif v.instance_of?(Array)
          result[k] = descend_array(v)
        elsif v.instance_of?(Proc)
          result[k] = v.()
        else
          result[k] = v
        end
      end
      result
    end


    def to_json(*args)
      to_hash.to_json(*args)
    end


    def merge!(hash)
      current = to_hash
      DeepMerge.deep_merge!(
        hash.dup,
        current,
        preserve_unmergeables: false,
        knockout_prefix:       ActiveSettings.knockout_prefix,
        overwrite_arrays:      ActiveSettings.overwrite_arrays,
        merge_nil_values:      ActiveSettings.merge_nil_values,
        keep_array_duplicates: ActiveSettings.keep_array_duplicates,
      )
      marshal_load(__convert(current).marshal_dump)
      self
    end


    def method_missing(method_name, *args)
      if ActiveSettings.fail_on_missing && method_name !~ /.*(?==\z)/m
        raise KeyError, "key not found: #{method_name.inspect}" unless key?(method_name)
      end
      super
    end


    protected


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
    def __convert(h) #:nodoc:
      s = ActiveSettings::Config.new

      h.each do |k, v|
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


    BOOLEAN_MAPPING = {
      'true'  => true,
      'false' => false,
    }.freeze

    # Try to convert boolean string to a correct type
    def __value(v)
      BOOLEAN_MAPPING.fetch(v) { auto_type(v) }
    end


    def auto_type(v)
      Integer(v) rescue Float(v) rescue v
    end

  end
end
