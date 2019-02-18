# frozen_string_literal: true

module ActiveSettings
  class Base < Config
    include Singleton

    extend  Validation::Schema
    include Validation::Validate

    class << self

      def source(source = nil)
        @source ||= source
      end

      def namespace(value = nil)
        @namespace ||= value
      end

      def to_json(*args)
        instance.to_json(*args)
      end

      private

        # rubocop:disable Style/MethodMissingSuper
        def method_missing(name, *args, &block)
          instance.send(name, *args, &block)
        end
        # rubocop:enable Style/MethodMissingSuper

    end


    def initialize(file = self.class.source)
      config = load_config_file(file)
      config = config[self.class.namespace] if self.class.namespace
      super(config)

      load_settings!
    end


    private


      def load_config_file(file)
        __convert load_yaml_file(file)
      end


      def load_yaml_file(file)
        YAML.load(ERB.new(IO.read(file)).result).to_hash
      end


      def load_settings!
        reload_env! if ActiveSettings.use_env
      end


      def reload_env!
        return self if ENV.nil? || ENV.empty?

        hash = {}

        ENV.each do |variable, value|
          separator = ActiveSettings.env_separator
          prefix = (ActiveSettings.env_prefix || ActiveSettings.const_name).to_s.split(separator)

          keys = variable.to_s.split(separator)

          next if keys.shift(prefix.size) != prefix

          keys.map! do |key|
            case ActiveSettings.env_converter
            when :downcase then
              key.downcase.to_sym
            when nil then
              key.to_sym
            else
              raise "Invalid ENV variables name converter: #{ActiveSettings.env_converter}"
            end
          end

          leaf = keys[0...-1].inject(hash) do |h, key|
            h[key] ||= {}
          end

          leaf[keys.last] = ActiveSettings.env_parse_values ? __value(value) : value
        end

        merge!(hash)
      end

  end
end
