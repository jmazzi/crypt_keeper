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
          ["SELECT AES_ENCRYPT(?, ?)", value, key]).first
      end

      # Public: Decrypts a string
      #
      # Returns a plaintext string
      def decrypt(values)
        values = Array(values)

        select = values.size.times.map do |i|
          "CASE ? WHEN NULL THEN NULL ELSE AES_DECRYPT(?, ?) END AS decrypt_#{i}"
        end.join(", ")

        args = values.map{ |value| [decoded(value), decoded(value), key] }.flatten

        escape_and_execute_sql(["SELECT #{select}", *args])
      end

      private

      def decoded(value)
        Base64.decode64(value) if value
      end
    end
  end
end
