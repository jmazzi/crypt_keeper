require 'crypt_keeper/log_subscriber/mysql_aes'

module CryptKeeper
  module Provider
    class MysqlAesNew < Base
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
      def decrypt(value)
        escape_and_execute_sql(
          ["SELECT AES_DECRYPT(?, ?)", Base64.decode64(value), key]).first
      end

      # Public: Searches the table
      #
      # Returns an Enumerable
      def search(records, field, criteria)
        records.where("#{field} = ?", encrypt(criteria))
      end

      private

      # Private: Sanitize an sql query and then execute it.
      #
      # query - the sql query
      #
      # Returns the response.
      def escape_and_execute_sql(query)
        query = ::ActiveRecord::Base.send :sanitize_sql_array, query
        ::ActiveRecord::Base.connection.execute(query).first
      end
    end
  end
end
