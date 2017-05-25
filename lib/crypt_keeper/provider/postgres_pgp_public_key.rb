require 'crypt_keeper/provider/postgres_base'

module CryptKeeper
  module Provider
    class PostgresPgpPublicKey < PostgresBase
      attr_accessor :key

      def initialize(options = {})
        ActiveSupport.run_load_hooks(:crypt_keeper_postgres_pgp_log, self)

        @key = options.fetch(:key) do
          raise ArgumentError, "Missing :key"
        end

        @public_key  = options.fetch(:public_key)
        @private_key = options[:private_key]
      end

      # Public: Encrypts a string
      #
      # Returns an encrypted string
      def encrypt(value)
        if !@private_key.present? && encrypted?(value)
          value
        else
          escape_and_execute_sql("SELECT pgp_pub_encrypt($1, dearmor($2))",
            "value" => value.to_s,
            "key" => @public_key
          )['pgp_pub_encrypt']
        end
      end

      # Public: Decrypts a string
      #
      # Returns a plaintext string
      def decrypt(value)
        if @private_key.present?
          escape_and_execute_sql("SELECT pgp_pub_decrypt($1, dearmor($2), $3)",
            "value" => value,
            "private_key" => @private_key,
            "key" => @key,
          )['pgp_pub_decrypt']
        else
          value
        end
      end

      # Public: Attempts to extract a PGP key id. If it's successful, it returns true
      #
      # Returns boolean
      def encrypted?(value)
        begin
          ActiveRecord::Base.transaction(requires_new: true) do
            escape_and_execute_sql("SELECT pgp_key_id($1)",
              "value" => value.to_s
            )['pgp_key_id'].present?
          end
        rescue ActiveRecord::StatementInvalid
          false
        end
      end
    end
  end
end
