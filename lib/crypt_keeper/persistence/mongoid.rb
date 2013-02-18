module CryptKeeper
  module Persistence
    module Mongoid

      # Public: Ensures that each field exist and is of type String. This prevents
      # encrypted data from being truncated.
      def ensure_valid_field!(field)
        if self.fields["#{field}"].nil?
          raise ArgumentError, "Field :#{field} does not exist"
        elsif self.fields["#{field}"].type != String
          raise ArgumentError, "Field :#{field} must be of type 'String' to be used for encryption"
        end
      end
    end
  end
end
