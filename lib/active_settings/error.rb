# frozen_string_literal: true

module ActiveSettings
  module Error
    class BaseError                 < StandardError; end
    class SourceFileNotDefinedError < BaseError; end
  end
end
