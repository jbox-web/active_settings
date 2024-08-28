# frozen_string_literal: true

module ActiveSettings
  module Validation
    module Schema

      def schema(&block)
        return @schema if @schema

        @schema = Dry::Schema.define(&block) if block
      end

    end
  end
end
