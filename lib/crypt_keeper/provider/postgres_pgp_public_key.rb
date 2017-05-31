require 'crypt_keeper/log_subscriber/postgres_pgp'

module CryptKeeper
  module Provider
    class PostgresPgpPublicKey < Base
      include CryptKeeper::Helper::SQL

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
          escape_and_execute_sql(["SELECT pgp_pub_encrypt(?, dearmor(?))", value.to_s, @public_key])['pgp_pub_encrypt']
        end
      end

      # Public: Decrypts a string
      #
      # Returns a plaintext string
      def decrypt(value)
        if @private_key.present?
          begin
            # check if the value is an encrypted value by querying its key id
            escape_and_execute_sql(["SELECT pgp_key_id(?)", value])
          rescue ActiveRecord::StatementInvalid
            # 'Wrong key or corrupt data', means the value is not an encrypted
            # value, so just the plaintext value
            return value
          end

          escape_and_execute_sql(["SELECT pgp_pub_decrypt(?, dearmor(?), ?)", value, @private_key, @key])['pgp_pub_decrypt']
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
            escape_and_execute_sql(["SELECT pgp_key_id(?)", value.to_s])['pgp_key_id'].present?
          end
        rescue ActiveRecord::StatementInvalid
          false
        end
      end
    end
  end
end
