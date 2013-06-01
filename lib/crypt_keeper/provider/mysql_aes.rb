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
      def encrypt(values)
        aes("AES_ENCRYPT", Array(values)).map { |v| Base64.encode64(v) }
      end

      # Public: Decrypts a string
      #
      # Returns a plaintext string
      def decrypt(values)
        aes("AES_DECRYPT", Array(values))
      end

      private

      def decoded(value)
        Base64.decode64(value) if value
      end

      def aes(action, values)
        if values.empty?
          []
        else
          select = values.size.times.map do |i|
            "CASE ? WHEN NULL THEN NULL ELSE #{action}(?, ?) END"
          end.join(", ")

          args = values.map{ |value| [decoded(value), decoded(value), key] }.flatten

          escape_and_execute_sql(["SELECT #{select}", *args])
        end
      end
    end
  end
end
