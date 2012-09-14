require 'crypt_keeper/log_subscriber/mysql_aes'

module CryptKeeper
  module Provider
    class MysqlAes
      attr_accessor :key

      # Public: Initializes the encryptor
      #
      #  options - A hash, :key is required
      def initialize(options = {})
        @key = options.fetch(:key) do
          raise ArgumentError, "Missing :key"
        end
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

      private

      # Private: Sanitize an sql query and then execute it
      def escape_and_execute_sql(query)
        query = ::ActiveRecord::Base.send :sanitize_sql_array, query
        ::ActiveRecord::Base.connection.execute(query).first
      end
    end
  end
end
