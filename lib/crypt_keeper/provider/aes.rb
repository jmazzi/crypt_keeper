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

      # Public: Whether blank string is accepted as data for encryption
      attr_accessor :strict_mode

      # Public: Initializes the class
      #
      #   options - A hash of options. :key is required
      def initialize(options = {})
        @aes         = ::OpenSSL::Cipher::Cipher.new("AES-256-CBC")
        @aes.padding = 1

        key = options.fetch(:key) do
          raise ArgumentError, "Missing :key"
        end

        @strict_mode = options.fetch(:strict_mode, true)

        @key = Digest::SHA256.digest(key)
      end

      # Public: Encrypt a string
      #
      # Returns a string
      def encrypt(value)
        if encryptable?(value)
          return '' if value == ''
          aes.encrypt
          aes.key = key
          Base64::encode64("#{aes.random_iv}#{SEPARATOR}#{aes.update(value.to_s) + aes.final}")
        else
          raise ArgumentError, "empty string not allowed in strict mode"
        end
      end

      # Public: Decrypt a string
      #
      # Returns a string
      def decrypt(value)
        if encryptable?(value)
          return '' if value == ''
          iv, value = Base64::decode64(value.to_s).split(SEPARATOR)
          aes.decrypt
          aes.key = key
          aes.iv  = iv
          aes.update(value) + aes.final
        else
          raise ArgumentError, "empty string not allowed in strict mode"
        end
      end

      protected

      # Protected: Determine if value can be encrypted
      #
      # Returns a boolean
      def encryptable?(value)
        if (value == '' && strict_mode)
          false
        else
          true
        end
      end
    end
  end
end
