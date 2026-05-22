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

      def platform(value = nil)
        @platform ||= value
      end

    end

    delegate :source, :environment, :platform, to: :class

    def initialize(file: self.class.source, environment: self.class.environment, platform: self.class.platform)
      raise ActiveSettings::Error::SourceFileNotDefinedError if file.nil?

      # load config from yaml file: settings.yml
      config = load_yaml_file(file)
      on_settings_file_load(file.to_s, loaded: true)

      # load config from environmentd yaml file: settings.dev.yml
      if environment
        ActiveSettings.deep_merge_hash!(config, load_environment_file(file, environment))
      end

      # load config from platform default file: settings_files/<platform>/default.yml
      if platform
        ActiveSettings.deep_merge_hash!(config, load_platform_file(file, platform))
      end

      # load config from platform+environment file: settings_files/<platform>/<env>.yml
      if platform && environment
        ActiveSettings.deep_merge_hash!(config, load_platform_environment_file(file, platform, environment))
      end

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
      loaded = File.exist?(ns_file)
      on_settings_file_load(ns_file, loaded: loaded)
      return {} unless loaded

      load_yaml_file(ns_file)
    end


    def load_platform_file(file, platform)
      ns_file = "#{File.dirname(file)}/settings_files/#{platform}/default.yml"
      loaded = File.exist?(ns_file)
      on_settings_file_load(ns_file, loaded: loaded)
      return {} unless loaded

      load_yaml_file(ns_file)
    end


    def load_platform_environment_file(file, platform, environment)
      ns_file = "#{File.dirname(file)}/settings_files/#{platform}/#{environment}.yml"
      loaded = File.exist?(ns_file)
      on_settings_file_load(ns_file, loaded: loaded)
      return {} unless loaded

      load_yaml_file(ns_file)
    end


    def load_yaml_file(file)
      ActiveSettings.load_yaml_file(file)
    end


    def on_settings_file_load(file, loaded:)
    end


    # rubocop:disable Style/EmptyMethod
    def before_initialize!
    end


    def after_initialize!
    end
    # rubocop:enable Style/EmptyMethod

  end
end
