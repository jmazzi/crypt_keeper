module CryptKeeper
  module Provider
    class PostgresPgp < PostgresBase
      attr_accessor :key
      attr_accessor :fallback_key
      attr_accessor :pgcrypto_options

      # Public: Initializes the encryptor
      #
      #  options - A hash of options.
      #    key - the encryption key (required)
      #    fallback_key - an alternative key to fallback to if decrypting using
      #                   `key` fails
      #    pgcrypto_options - custom options for pgcrypto
      def initialize(options = {})
        ActiveSupport.run_load_hooks(:crypt_keeper_postgres_pgp_log, self)

        @key = options.fetch(:key) do
          raise ArgumentError, "Missing :key"
        end

        @fallback_key = options.fetch(:fallback_key, nil)

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
            begin
              execute_decrypt(value, key)
            rescue ActiveRecord::StatementInvalid
              if fallback_key.present?
                execute_decrypt(value, fallback_key)
              else
                raise
              end
            end
          else
            value
          end
        end
      end

      def search(records, field, criteria)
        records.where("(pgp_sym_decrypt(cast(\"#{field}\" AS bytea), ?) = ?)",
          key, criteria)
      end

      private

      # Private: Decrypts a string.
      #
      # Returns a plaintext string
      def execute_decrypt(value, key)
        escape_and_execute_sql(["SELECT pgp_sym_decrypt(?, ?)",
          value, key])['pgp_sym_decrypt']
      end

      # Private: Rescues and filters invalid statement errors. Run the code
      # within a block for it to be rescued.
      def rescue_invalid_statement
        result = begin
          yield
        rescue ActiveRecord::StatementInvalid => e
          e
        end

        # Manually check for the exception instead of using a normal
        # begin/rescue because if you raise an exception inside a rescue,
        # the raised exception will also include the `cause`.
        #
        # Due to `cause` being created by Ruby internals, we can't manipulate
        # its value to hide the pgcrypto secrets, so avoid it instead.
        if result.is_a?(ActiveRecord::StatementInvalid)
          message = crypt_keeper_payload_parse(result.message)
          message = crypt_keeper_filter_postgres_log(message)
          raise ActiveRecord::StatementInvalid, message
        else
          result
        end
      end
    end
  end
end
