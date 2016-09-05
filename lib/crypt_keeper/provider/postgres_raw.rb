require 'crypt_keeper/log_subscriber/postgres_raw'

module CryptKeeper
  module Provider
    class PostgresRaw
      include CryptKeeper::Helper::SQL

      attr_accessor :key
      attr_accessor :iv
      attr_accessor :pgcrypto_options
      # Public: Initializes the encryptor
      #
      #  options - A hash, :key is required
      def initialize(options = {})
        ActiveSupport.run_load_hooks(:crypt_keeper_postgres_raw_log, self)

        @key = options.fetch(:key) do
          raise ArgumentError, "Missing :key"
        end

        @iv = options[:iv]
        @pgcrypto_options = options.fetch(:pgcrypto_options, 'aes')
      end

      # Public: Encrypts a string
      #
      # Returns an encrypted string
      def encrypt(value)
        if iv
          escape_and_execute_sql(["SELECT encrypt_iv(?, ?, ?, ?)", value.to_s, key, iv, pgcrypto_options])['encrypt_iv']
        else
          escape_and_execute_sql(["SELECT encrypt(?, ?, ?)", value.to_s, key, pgcrypto_options])['encrypt']
        end
      end

      # Public: Decrypts a string
      #
      # Returns a plaintext string
      def decrypt(value)
        if iv
          escape_and_execute_sql(["SELECT encode(decrypt_iv(bytea(?), ?, ?, ?), 'escape')", value, key, iv, pgcrypto_options])['encode']
        else
          escape_and_execute_sql(["SELECT encode(decrypt(bytea(?), ?, ?), 'escape')", value, key, pgcrypto_options])['encode']
        end
      end

      def search(records, field, criteria)
        records.where("#{field} = ?", encrypt(criteria))
      end

    end
  end
end
