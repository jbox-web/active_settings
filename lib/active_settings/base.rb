# frozen_string_literal: true

module ActiveSettings
  class Base < Config
    include Singleton

    extend  ActiveSettings::Validation::Schema
    include ActiveSettings::Validation::Validate

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

      def method_missing(name, *args, &block)
        instance.send(name, *args, &block)
      end

    end


    def initialize(file = self.class.source)
      raise ActiveSettings::Error::SourceFileNotDefinedError if file.nil?

      config = load_config_file(file)
      config = config[self.class.namespace] if self.class.namespace
      super(config)

      load_settings!
    end


    private


    def load_config_file(file)
      __convert load_yaml_file(file)
    end


    # rubocop:disable Security/YAMLLoad
    def load_yaml_file(file)
      YAML.load(ERB.new(File.read(file)).result).to_hash
    end
    # rubocop:enable Security/YAMLLoad


    def load_settings!
      reload_env! if ActiveSettings.use_env
    end


    # Borrowed from [config gem](https://github.com/rubyconfig/config/blob/master/lib/config/options.rb)
    # See: https://github.com/rubyconfig/config/commit/351c819f75d53aa5621a226b5957c79ac82ded11
    # rubocop:disable Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/AbcSize
    def reload_env!
      return if ENV.nil? || ENV.empty?

      hash = {}

      ENV.each do |variable, value|
        separator = ActiveSettings.env_separator
        prefix = (ActiveSettings.env_prefix || ActiveSettings.const_name).to_s.split(separator)

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

        leaf[keys.last] = ActiveSettings.env_parse_values ? __value(value) : value
      end

      merge!(hash)
    end
    # rubocop:enable Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/AbcSize

  end
end
