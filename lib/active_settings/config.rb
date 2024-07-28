# frozen_string_literal: true

# Borrowed from [config gem](https://github.com/rubyconfig/config)
# See: https://github.com/rubyconfig/config/blob/master/lib/config/options.rb

module ActiveSettings
  class Config < OpenStruct

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
      ActiveSettings.to_hash(self)
    end

    alias :to_h :to_hash


    def to_json(*args)
      to_hash.to_json(*args)
    end


    def merge!(other)
      current = to_hash
      other = other.dup
      ActiveSettings.deep_merge_hash!(current, other)
      marshal_load(ActiveSettings.from_hash(current).marshal_dump)
      self
    end


    def freeze
      ActiveSettings.deep_freeze(self)
      super
    end


    # rubocop:disable Style/SoleNestedConditional
    def method_missing(method_name, *args)
      return super if method_name == :respond_to_missing?

      if ActiveSettings.fail_on_missing && method_name !~ /.*(?==\z)/m
        raise KeyError, "key not found: #{method_name.inspect}" unless key?(method_name)
      end

      super
    end
    # rubocop:enable Style/SoleNestedConditional


    def respond_to_missing?(method_name, include_private = false)
      key?(method_name) || super
    end

    public :respond_to_missing?

  end
end
