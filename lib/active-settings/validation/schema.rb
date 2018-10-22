# frozen_string_literal: true

require 'dry-validation'

module ActiveSettings
  module Validation
    module Schema

      def schema(&block)
        return @schema if @schema

        @schema = Dry::Validation.Schema(&block) if block_given?
      end

    end
  end
end
