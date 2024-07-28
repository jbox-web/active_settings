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

    end

    delegate :source, :namespace, to: :class

    def initialize(file: self.class.source, namespace: self.class.namespace)
      raise ActiveSettings::Error::SourceFileNotDefinedError if file.nil?

      config = load_yaml_file(file)
      ActiveSettings.deep_merge_hash!(config, load_namespace_file(file, namespace)) if namespace

      super(ActiveSettings.from_hash(config))

      before_initialize!

      merge!(ActiveSettings.from_env(ENV))

      yield if block_given?

      after_initialize!
    end


    private


    def load_namespace_file(file, namespace)
      ns_file = "#{File.dirname(file)}/#{File.basename(file, File.extname(file))}.#{namespace}.yml"
      return {} unless File.exist?(ns_file)

      load_yaml_file(ns_file)
    end


    def load_yaml_file(file)
      ActiveSettings.load_yaml_file(file)
    end


    # rubocop:disable Style/EmptyMethod
    def before_initialize!
    end


    def after_initialize!
    end
    # rubocop:enable Style/EmptyMethod

  end
end
