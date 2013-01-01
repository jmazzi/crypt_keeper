require 'crypt_keeper/log_subscriber/postgres_pgp'

module CryptKeeper
  module Provider
    class PostgresPgp
      include CryptKeeper::Helper::SQL
      attr_accessor :key

      # Public: Initializes the encryptor
      #
      #  options - A hash, :key is required
      def initialize(options = {})
        ActiveSupport.run_load_hooks(:crypt_keeper_posgres_pgp_log, self)

        @key = options.fetch(:key) do
          raise ArgumentError, "Missing :key"
        end
      end

      # Public: Encrypts a string
      #
      # Returns an encrypted string
      def encrypt(value)
        escape_and_execute_sql(["SELECT pgp_sym_encrypt(?, ?)", value.to_s, key])['pgp_sym_encrypt']
      end

      # Public: Decrypts a string
      #
      # Returns a plaintext string
      def decrypt(value)
        escape_and_execute_sql(["SELECT pgp_sym_decrypt(?, ?)", value, key])['pgp_sym_decrypt']
      end

      # Public: Creates SQL string for selecting decrypted value
      #
      # column - column to decorate
      # alias - column alias
      # Returns SQL string with decrypt function applied to column name and aliased to column alias
      def column_for_select(column, column_alias)
        escape_sql(["pgp_sym_decrypt(#{column}::bytea, ?) AS \"#{column_alias}\"", key])
      end
    end
  end
end
