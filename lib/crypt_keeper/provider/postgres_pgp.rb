module CryptKeeper
  module Provider
    class PostgresPgp < PostgresBase
      attr_accessor :key
      attr_accessor :pgcrypto_options

      # Public: Initializes the encryptor
      #
      #  options - A hash, :key is required
      def initialize(options = {})
        ::ActiveSupport.run_load_hooks(:crypt_keeper_postgres_pgp_log, self)

        @key = options.fetch(:key) do
          raise ArgumentError, "Missing :key"
        end

        @pgcrypto_options = options.fetch(:pgcrypto_options, '')
      end

      # Public: Encrypts a string
      #
      # Returns an encrypted string
      def encrypt(value)
        rescue_invalid_statement do
          escape_and_execute_sql(["SELECT pgp_sym_encrypt(?, ?, ?)",
            value.to_s, key, pgcrypto_options])['pgp_sym_encrypt']
        end
      end

      # Public: Decrypts a string
      #
      # Returns a plaintext string
      def decrypt(value)
        rescue_invalid_statement do
          if encrypted?(value)
            escape_and_execute_sql(["SELECT pgp_sym_decrypt(?, ?)",
              value, key])['pgp_sym_decrypt']
          else
            value
          end
        end
      end

      def search(records, field, criteria)
        if criteria.present?
          records
            .where.not("TRIM(BOTH FROM #{field}) = ?", "")
            .where("(pgp_sym_decrypt(cast(\"#{field}\" AS bytea), ?) = ?)",
                   key, criteria)
        else
          records.where("#{field}" => criteria)
        end
      end

      private

      # Private: Rescues and filters invalid statement errors. Run the code
      # within a block for it to be rescued.
      def rescue_invalid_statement
        yield
      rescue ActiveRecord::StatementInvalid => e
        message = crypt_keeper_payload_parse(e.message)
        message = crypt_keeper_filter_postgres_log(message)
        raise ActiveRecord::StatementInvalid, message
      end
    end
  end
end
