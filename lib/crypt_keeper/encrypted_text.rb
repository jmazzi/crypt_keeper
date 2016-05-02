module CryptKeeper
  class EncryptedText < ActiveRecord::Type::String
    def type
      :text
    end

    def changed_in_place?(raw_old_value, new_value)
      if new_value.is_a?(::String)
        # Raw encrypted version could be different for the same value
        # so we need to decrypt first
        raw_old_value != new_value
      end
    end
  end
end