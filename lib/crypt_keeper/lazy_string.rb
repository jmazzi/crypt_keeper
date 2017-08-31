module CryptKeeper
  # LazyString is a wrapper around a String instance to avoid immediatelly
  # decrypting the String value. Decryption operations can be slow, so by
  # using the LazyString, decryption is only triggered if the String values
  # are actually accessed.
  class LazyString < BasicObject
    attr_accessor :provider, :encrypted_string

    # Public: Initializes the LazyString.
    #
    # provider - the CryptKeeper provider instance
    # encrypted_string - the encrypted string instance
    def initialize(provider, encrypted_string)
      @provider = provider
      @encrypted_string = encrypted_string
    end

    # Public: Overrides == to compare the decrypted string to the other object.
    #
    # other - the other object to compare this to
    #
    # Returns a boolean.
    def ==(other)
      decrypted_string == other
    end

    # Public: Implements to_str for String compatibility.
    #
    # Returns the decrypted string.
    def to_str
      decrypted_string
    end

    # TODO: RSPEC ASKS FOR THIS, WHY?
    # Public: Implements to_ary for String compatibility.
    #
    # Returns the decrypted string.
    def to_ary
      nil
    end

    private

    # Private: Delegates all calls to the decrypted string.
    #
    # name - the method name
    # *args - the methods args
    # block - a block if needed
    def method_missing(name, *args, &block)
      # Forward string methods to the decrypted_string.
      #
      # Some classes implemented in C will try to convert a non String object
      # (like LazyString) calling a conversion method (for example,
      # OpenSSL::PKey::RSA.new will try to call `to_der` on the LazyString).
      #
      # String does not respond to that, but it happened because the C
      # implementation expected an actual String. In that case, just return
      # the decrypted_string directly.
      if decrypted_string.respond_to?(name)
        decrypted_string.send(name, *args, &block)
      else
        decrypted_string
      end
    end

    # Private: Decrypts the encrypted string using the provider.
    #
    # Returns a String.
    def decrypted_string
      @decrypted_string ||= provider.lazy_decrypt(@encrypted_string)
    end
  end
end
