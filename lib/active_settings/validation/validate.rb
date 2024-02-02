# frozen_string_literal: true

module ActiveSettings
  module Validation
    module Validate

      def validate!
        return unless self.class.schema

        v_res = self.class.schema.call(to_hash)

        return if v_res.success?

        raise ActiveSettings::Validation::Error, "ActiveSettings validation failed:\n\n#{ActiveSettings::Validation::Error.format(v_res, ActiveSettings.env_prefix)}"
      end

    end
  end
end
