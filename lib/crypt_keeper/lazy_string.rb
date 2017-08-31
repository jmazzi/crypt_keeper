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
      decrypted_string.send(name, *args, &block)
    end

    # Private: Decrypts the encrypted string using the provider.
    #
    # Returns a String.
    def decrypted_string
      @decrypted_string ||= provider.lazy_decrypt(@encrypted_string)
    end
  end
end
