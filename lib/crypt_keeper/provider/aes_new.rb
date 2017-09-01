require 'aes'
require 'armor'

module CryptKeeper
  module Provider
    class AesNew < Base
      include CryptKeeper::Helper::DigestPassphrase

      # Public: The encryption key
      attr_accessor :key

      # Public: Initializes the class
      #
      #   options - A hash of options. :key and :salt are required
      def initialize(options = {})
        @key = digest_passphrase(options[:key], options[:salt])
      end

      # Public: Encrypt a string
      #
      # Note: nil and empty strings are not encryptable with AES.
      # When they are encountered, the orignal value is returned.
      # Otherwise, returns the encrypted string
      #
      # Returns a String
      def encrypt(value)
        AES.encrypt(value, key)
      end

      # Public: Decrypt a string
      #
      # Note: nil and empty strings are not encryptable with AES (and thus cannot be decrypted).
      # When they are encountered, the orignal value is returned.
      # Otherwise, returns the decrypted string
      #
      # Returns a String
      def lazy_decrypt(value)
        AES.decrypt(value, key)
      end

      # Public: Search for a record
      #
      # record   - An ActiveRecord collection
      # field    - The field to search
      # criteria - A string to search with
      #
      # Returns an Enumerable
      def search(records, field, criteria)
        records.select { |record| record[field] == criteria }
      end
    end
  end
end
