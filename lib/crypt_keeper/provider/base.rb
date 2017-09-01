module CryptKeeper
  module Provider
    class Base
      def dump(value)
        if value.blank? || CryptKeeper.stub_encryption?
          value
        else
          encrypt(value.to_s)
        end
      end

      def load(value)
        if value.blank? || CryptKeeper.stub_encryption?
          value
        else
          decrypt(value)
        end
      end

      # Public: Subclasses should implement their own `encrypt` method.
      #
      # value - the String to encrypt
      #
      # Returns a String.
      def encrypt(value)
        NotImplementedError
      end

      # Public: Decrypts a string. This will not immediatelly decrypt the String,
      # but will return a LazyString instance instead. The LazyString will
      # run the actual decription (through `lazy_decrypt`) when it eventually
      # is called upon.
      #
      # Returns a LazyString.
      def decrypt(value)
        LazyString.new(self, value)
      end

      # Public: Subclasses should implement their own `decrypt` method.
      #
      # value - the String to decrypt
      #
      # Returns a String.
      def lazy_decrypt(value)
        NotImplementedError
      end
    end
  end
end
