module CryptKeeper
  module Persistence
    module ActiveRecordPersistence

      # Public: Ensures that each field exist and is of type text. This prevents
      # encrypted data from being truncated.
      def ensure_valid_field!(field)
        if self.class.columns_hash["#{field}"].nil?
          raise ArgumentError, "Column :#{field} does not exist"
        elsif self.class.columns_hash["#{field}"].type != :text
          raise ArgumentError, "Column :#{field} must be of type 'text' to be used for encryption"
        end
      end
    end
  end
end
