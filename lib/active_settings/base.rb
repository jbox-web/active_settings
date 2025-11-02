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

      # load config from yaml file: settings.yml
      config = load_yaml_file(file)

      # load config from namespaced yaml file: settings.dev.yml
      ActiveSettings.deep_merge_hash!(config, load_namespace_file(file, namespace)) if namespace

      # create settings object
      super(ActiveSettings.from_hash(config))

      # run before initialize hook (to load env vars for example)
      before_initialize!

      # merge settings from env vars
      merge!(ActiveSettings.from_env(ENV))

      # yield to block for further customization
      yield if block_given?

      # run after initialize hook (to create directories for example)
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
