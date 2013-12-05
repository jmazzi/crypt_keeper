require 'crypt_keeper/log_subscriber/postgres_pgp'

module CryptKeeper
  module Provider
    class PostgresPgpSym
      include CryptKeeper::Helper::SQL

      def initialize(key, options)
        @key     = key
        @options = options
      end

      # Public: Encrypts a string
      #
      # Returns an encrypted string
      def encrypt(value)
        escape_and_execute_sql(["SELECT pgp_sym_encrypt(?, ?, ?)", value.to_s, @key, @options])['pgp_sym_encrypt']
      end

      # Public: Decrypts a string
      #
      # Returns a plaintext string
      def decrypt(value)
        escape_and_execute_sql(["SELECT pgp_sym_decrypt(?, ?)", value, @key])['pgp_sym_decrypt']
      end
    end

    class PostgresPgp
      attr_accessor :key

      # Public: Initializes the encryptor
      #
      #  options - A hash, :key is required
      def initialize(options = {})
        ActiveSupport.run_load_hooks(:crypt_keeper_posgres_pgp_log, self)

        @key = options.fetch(:key) do
          raise ArgumentError, "Missing :key"
        end

        @pgcrypto_options = options.delete(:pgcrypto_options) || ''
        @options          = options
      end

      # Public: Encrypts a string
      #
      # Returns an encrypted string
      def encrypt(value)
        decrypt_class.new(key, @pgcrypto_options).encrypt(value)
      end

      # Public: Decrypts a string
      #
      # Returns a plaintext string
      def decrypt(value)
        decrypt_class.new(key, @pgcrypto_options).decrypt(value)
      end

      def search(records, field, criteria)
        records.where("(pgp_sym_decrypt(cast(#{field} AS bytea), ?) = ?)", key, criteria)
      end

      def decrypt_class
        @options[:public] ? PostgresPgpPublic : PostgresPgpSym
      end
    end
  end
end
