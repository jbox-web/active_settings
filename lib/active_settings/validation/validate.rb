# frozen_string_literal: true

module ActiveSettings
  module Validation
    module Validate

      def validate!
        if self.class.schema
          v_res = self.class.schema.(to_hash)

          unless v_res.success?
            raise ActiveSettings::Validation::Error.new("ActiveSettings validation failed:\n\n#{ActiveSettings::Validation::Error.format(v_res)}")
          end
        end
      end

    end
  end
end
