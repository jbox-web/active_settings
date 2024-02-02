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

      # Borrowed from [config gem](https://github.com/rubyconfig/config/blob/master/lib/config/options.rb)
      # See: https://github.com/rubyconfig/config/commit/351c819f75d53aa5621a226b5957c79ac82ded11
      # rubocop:disable Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/AbcSize, Metrics/PerceivedComplexity
      def reload_env
        return if ENV.nil? || ENV.empty?

        raise ActiveSettings::Error::EnvPrefixNotDefinedError if ActiveSettings.env_prefix.nil?

        separator = ActiveSettings.env_separator
        prefix = ActiveSettings.env_prefix.to_s.split(separator)

        hash = {}

        ENV.each do |variable, value|
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

        hash
      end
      # rubocop:enable Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/AbcSize, Metrics/PerceivedComplexity

      private

      def method_missing(name, *args, &block)
        instance.send(name, *args, &block)
      end

      def respond_to_missing?(*args)
        instance.respond_to_missing(*args)
      end

    end

    delegate :source, :namespace, to: :class

    def initialize(file = self.class.source, namespace = self.class.namespace)
      raise ActiveSettings::Error::SourceFileNotDefinedError if file.nil?

      config = load_config_file(file)
      self.class.deep_merge!(config, load_namespace_file(file, namespace)) if namespace

      super(self.class.convert_hash(config))

      yield if block_given?

      reload_env! if ActiveSettings.use_env

      after_initialize!
    end


    private


    def load_config_file(file)
      load_yaml_file(file)
    end


    def load_namespace_file(file, namespace)
      ns_file = build_namespace_file_path(file, namespace)
      return {} unless File.exist?(ns_file)

      load_config_file(ns_file)
    end


    def build_namespace_file_path(file, namespace)
      "#{File.dirname(file)}/#{File.basename(file, File.extname(file))}.#{namespace}.yml"
    end


    # rubocop:disable Security/YAMLLoad
    def load_yaml_file(file)
      begin
        YAML.load(ERB.new(File.read(file)).result, aliases: true).to_hash
      rescue ArgumentError => e
        YAML.load(ERB.new(File.read(file)).result).to_hash
      end
    end
    # rubocop:enable Security/YAMLLoad


    def reload_env!
      merge!(self.class.reload_env)
    end


    def after_initialize!
    end

  end
end
