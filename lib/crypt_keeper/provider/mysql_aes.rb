require 'crypt_keeper/log_subscriber/mysql_aes'

module CryptKeeper
  module Provider
    class MysqlAes
      include CryptKeeper::Helper::SQL

      attr_accessor :key

      # Public: Initializes the encryptor
      #
      #  options - A hash, :key is required
      def initialize(options = {})
        ActiveSupport.run_load_hooks(:crypt_keeper_mysql_aes_log, self)

        @key = options.fetch(:key) do
          raise ArgumentError, "Missing :key"
        end
      end

      # Public: Encrypts a string
      #
      # Returns an encrypted string
      def encrypt(value)
        Base64.encode64 escape_and_execute_sql(
          ["SELECT AES_ENCRYPT(?, ?) AS ciphertext", value, key])['ciphertext']
      end

      # Public: Decrypts a string
      #
      # Returns a plaintext string
      def decrypt(value)
        escape_and_execute_sql(
          ["SELECT AES_DECRYPT(?, ?) AS plaintext", Base64.decode64(value), key])['plaintext']
      end
    end
  end
end
