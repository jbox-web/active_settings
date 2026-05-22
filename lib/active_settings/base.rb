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

      def environment(value = nil)
        @environment ||= value
      end

    end

    delegate :source, :environment, to: :class

    def initialize(file: self.class.source, environment: self.class.environment)
      raise ActiveSettings::Error::SourceFileNotDefinedError if file.nil?

      # load config from yaml file: settings.yml
      config = load_yaml_file(file)

      # load config from environmentd yaml file: settings.dev.yml
      ActiveSettings.deep_merge_hash!(config, load_environment_file(file, environment)) if environment

      # run before initialize hook (to load env vars for example)
      before_initialize!

      # create settings object
      super(ActiveSettings.from_hash(config))

      # merge settings from env vars
      merge!(ActiveSettings.from_env(ENV))

      # yield to block for further customization
      yield if block_given?

      # run after initialize hook (to create directories for example)
      after_initialize!
    end


    private


    def load_environment_file(file, environment)
      ns_file = "#{File.dirname(file)}/#{File.basename(file, File.extname(file))}.#{environment}.yml"
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
