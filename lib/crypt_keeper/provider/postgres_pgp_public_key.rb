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
          escape_and_execute_sql(["SELECT pgp_pub_encrypt(?, dearmor(?))", value.to_s, @public_key])['pgp_pub_encrypt']
        end
      end

      def lazy_decrypt(value)
        if @private_key.present? && encrypted?(value)
          escape_and_execute_sql(["SELECT pgp_pub_decrypt(?, dearmor(?), ?)",
            value, @private_key, @key])['pgp_pub_decrypt']
        else
          value
        end
      end
    end
  end
end
