# A fake class that does no encryption
module CryptKeeper
  module Provider
    class FakeEncryptor
      def initialize(*args)
      end
    end
  end
end

# This class embeds the passphrase in the beginning of the string
# and then reverses the 'plaintext'
module CryptKeeper
  module Provider
    class Encryptor
      def initialize(options = {})
        @passphrase = options[:passphrase]
      end

      def encrypt(data)
        Array(data).map { |d| @passphrase + d.reverse }
      end

      def decrypt(data)
        Array(data).map { |d| d.to_s.sub(/^#{@passphrase}/, '').reverse }
      end
    end
  end
end
