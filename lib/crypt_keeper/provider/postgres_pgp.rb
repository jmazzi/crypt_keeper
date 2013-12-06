require 'crypt_keeper/log_subscriber/postgres_pgp'
require 'forwardable'

module CryptKeeper
  module Provider
    class PostgresPgpSym
      include CryptKeeper::Helper::SQL

      def initialize(key, options)
        @key              = key
        @pgcrypto_options = options.delete(:pgcrypto_options) || ''
      end

      # Public: Encrypts a string
      #
      # Returns an encrypted string
      def encrypt(value)
        escape_and_execute_sql(["SELECT pgp_sym_encrypt(?, ?, ?)", value.to_s, @key, @pgcrypto_options])['pgp_sym_encrypt']
      end

      # Public: Decrypts a string
      #
      # Returns a plaintext string
      def decrypt(value)
        escape_and_execute_sql(["SELECT pgp_sym_decrypt(?, ?)", value, @key])['pgp_sym_decrypt']
      end

      def search(records, field, criteria)
        records.where("(pgp_sym_decrypt(cast(#{field} AS bytea), ?) = ?)", @key, criteria)
      end
    end

    class PostgresPgpPublic
      include CryptKeeper::Helper::SQL

      def initialize(key, options)
        @key         = key
        @public_key  = options.fetch(:public_key)
        @private_key = options.fetch(:private_key)
      end

      # Public: Encrypts a string
      #
      # Returns an encrypted string
      def encrypt(value)
        escape_and_execute_sql(["SELECT pgp_pub_encrypt(?, dearmor(?))", value.to_s, @public_key])['pgp_pub_encrypt']
      end

      # Public: Decrypts a string
      #
      # Returns a plaintext string
      def decrypt(value)
        escape_and_execute_sql(["SELECT pgp_pub_decrypt(?, dearmor(?), ?)", value, @private_key, @key])['pgp_pub_decrypt']
      end
    end

    class PostgresPgp
      extend Forwardable

      def_delegators :@encryption_class, :encrypt, :decrypt, :search

      attr_reader :key

      # Public: Initializes the encryptor
      #
      #  options - A hash, :key is required
      def initialize(options = {})
        ActiveSupport.run_load_hooks(:crypt_keeper_posgres_pgp_log, self)

        @key = options.fetch(:key) do
          raise ArgumentError, "Missing :key"
        end

        @options          = options
        @encryption_class = decrypt_class.new(@key, @options)
      end

      def decrypt_class
        @options[:public_key] ? PostgresPgpPublic : PostgresPgpSym
      end
    end
  end
end
