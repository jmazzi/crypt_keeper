require "active_support/message_encryptor"

module CryptKeeper
  module Provider
    class ActiveSupport < Base
      attr_reader :encryptor

      # Public: Initializes the encryptor
      #
      # options - A hash, :key and :salt are required
      #
      # Returns nothing.
      def initialize(options = {})
        key  = options.fetch(:key)
        salt = options.fetch(:salt)

        @encryptor = ::ActiveSupport::MessageEncryptor.new \
          ::ActiveSupport::KeyGenerator.new(key).generate_key(salt, 32)
      end

      # Public: Encrypts a string
      #
      # value - Plaintext value
      #
      # Returns an encrypted string
      def encrypt(value)
        encryptor.encrypt_and_sign(value)
      end

      # Public: Decrypts a string
      #
      # value - Cipher text
      #
      # Returns a plaintext string
      def decrypt(value)
        encryptor.decrypt_and_verify(value)
      end

      # Public: Searches the table
      #
      # records  - ActiveRecord::Relation
      # field    - Field name to match
      # criteria - Value to match
      #
      # Returns an Enumerable
      def search(records, field, criteria)
        records.select { |record| record[field] == criteria }
      end
    end
  end
end
