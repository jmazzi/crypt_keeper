module CryptKeeper
  module Helper
    module DigestPassphrase
      def digest_passphrase(key, salt)
        raise ArgumentError.new("Missing :key") if key.blank?
        raise ArgumentError.new("Missing :salt") if salt.blank?
        ::Armor.digest(key, salt)
      end
    end
  end
end
