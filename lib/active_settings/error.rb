# frozen_string_literal: true

module ActiveSettings
  module Error
    class BaseError                 < StandardError; end
    class SourceFileNotDefinedError < BaseError; end
    class EnvPrefixNotDefinedError  < BaseError; end
  end
end
