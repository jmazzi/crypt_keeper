# A fake class that does no encryption
module CryptKeeperProviders
  class FakeEncryptor
    def initialize(*args)
    end
  end
end

# This class embeds the passphrase in the beginning of the string
# and then reverses the 'plaintext'
module CryptKeeperProviders
  class Encryptor
    def initialize(options = {})
      @passphrase = options[:passphrase]
    end

    def encrypt(data)
      @passphrase + data.reverse
    end

    def decrypt(data)
      data.sub(/^#{@passphrase}/, '').reverse
    end
  end
end

