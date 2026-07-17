# frozen_string_literal: true

module ActiveSettings
  module Error
    class BaseError                 < StandardError; end
    class SourceFileNotDefinedError < BaseError; end
    class EnvPrefixNotDefinedError  < BaseError; end
    class InvalidSettingsFileError  < BaseError; end
    class EnvKeyConflictError       < BaseError; end
  end
end
