require 'crypt_keeper/log_subscriber/mysql_aes'

module CryptKeeper
  module Provider
    class MysqlAesNew < Base
      include CryptKeeper::Helper::SQL
      include CryptKeeper::Helper::DigestPassphrase

      attr_accessor :key

      # Public: Initializes the encryptor
      #
      #  options - A hash, :key and :salt are required
      def initialize(options = {})
        ActiveSupport.run_load_hooks(:crypt_keeper_mysql_aes_log, self)
        @key = digest_passphrase(options[:key], options[:salt])
      end

      # Public: Encrypts a string
      #
      # Returns an encrypted string
      def encrypt(value)
        Base64.encode64 escape_and_execute_sql(
          ["SELECT AES_ENCRYPT(?, ?)", value, key]).first
      end

      # Public: Decrypts a string
      #
      # Returns a plaintext string
      def lazy_decrypt(value)
        escape_and_execute_sql(
          ["SELECT AES_DECRYPT(?, ?)", Base64.decode64(value), key]).first
      end

      # Public: Searches the table
      #
      # Returns an Enumerable
      def search(records, field, criteria)
        records.where("#{field} = ?", encrypt(criteria))
      end
    end
  end
end
