require 'crypt_keeper/provider/postgres_base'

module CryptKeeper
  module Provider
    class PostgresPgp < PostgresBase
      attr_accessor :key
      attr_accessor :pgcrypto_options

      # Public: Initializes the encryptor
      #
      #  options - A hash, :key is required
      def initialize(options = {})
        ActiveSupport.run_load_hooks(:crypt_keeper_postgres_pgp_log, self)

        @key = options.fetch(:key) do
          raise ArgumentError, "Missing :key"
        end

        @pgcrypto_options = options.fetch(:pgcrypto_options, '')
      end

      # Public: Encrypts a string
      #
      # Returns an encrypted string
      def encrypt(value)
        escape_and_execute_sql("SELECT pgp_sym_encrypt($1, $2, $3)",
          "value" => value.to_s,
          "key" => key,
          "options" => pgcrypto_options
        )['pgp_sym_encrypt']
      end

      # Public: Decrypts a string
      #
      # Returns a plaintext string
      def decrypt(value)
        escape_and_execute_sql("SELECT pgp_sym_decrypt($1, $2)",
          "value" => value,
          "key" => key,
        )['pgp_sym_decrypt']
      end

      def search(records, field, criteria)
        records.where("(pgp_sym_decrypt(cast(\"#{field}\" AS bytea), ?) = ?)",
          key, criteria)
      end
    end
  end
end
