require 'digest/sha2'
require 'openssl'
require 'base64'

module CryptKeeper
  module Provider
    class Aes
      SEPARATOR = ":crypt_keeper:"

      # Public: The encryption key
      attr_accessor :key

      # Public: An instance of  OpenSSL::Cipher::Cipher
      attr_accessor :aes

      # Public: Initializes the class
      #
      #   options - A hash of options. :key is required
      def initialize(options = {})
        @aes         = ::OpenSSL::Cipher::Cipher.new("AES-256-CBC")
        @aes.padding = 1

        key = options.fetch(:key) do
          raise ArgumentError, "Missing :key"
        end

        @key = Digest::SHA256.digest(key)
      end

      # Public: Encrypt a string
      #
      # Note: nil and empty strings are not encryptable with AES.
      # When they are encountered, the orignal value is returned.
      # Otherwise, returns the encrypted string
      def encrypt(values)
        Array(values).map { |value| encrypt_value(value) }
      end

      # Public: Decrypt a string
      #
      # Note: nil and empty strings are not encryptable with AES (and thus cannot be decrypted).
      # When they are encountered, the orignal value is returned.
      # Otherwise, returns the decrypted string
      def decrypt(values)
        Array(values).map { |value| decrypt_value(value) }
      end

      private

      def encrypt_value(value)
        return value if value == '' || value.nil?
        aes.encrypt
        aes.key = key
        Base64::encode64("#{aes.random_iv}#{SEPARATOR}#{aes.update(value.to_s) + aes.final}")
      end

      def decrypt_value(value)
        return value if value == '' || value.nil?
        iv, value = Base64::decode64(value.to_s).split(SEPARATOR)
        aes.decrypt
        aes.key = key
        aes.iv  = iv
        aes.update(value) + aes.final
      end
    end
  end
end
