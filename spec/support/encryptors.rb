# A fake class that does no encryption
module CryptKeeper
  module Provider
    class FakeEncryptor
      include CryptKeeper::Helper::Serializer

      def initialize(*args)
      end

      def encrypt(value)
        value
      end

      def decrypt(value)
        value
      end
    end
  end
end

# This class embeds the passphrase in the beginning of the string
# and then reverses the 'plaintext'
module CryptKeeper
  module Provider
    class Encryptor
      include CryptKeeper::Helper::Serializer

      def initialize(options = {})
        @passphrase = options[:passphrase]
      end

      def encrypt(data)
        @passphrase + data.reverse
      end

      def decrypt(data)
        data.to_s.sub(/^#{@passphrase}/, '').reverse
      end
    end
  end
end
