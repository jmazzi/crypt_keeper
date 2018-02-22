module CryptKeeper
  module Helper
    module SQL
      private

      # Private: Sanitize an sql query and then execute it.
      #
      # query - the sql query
      # new_transaction - if the query should run inside a new transaction
      #
      # Returns the ActiveRecord response.
      def escape_and_execute_sql(query, new_transaction: false)
        query = ::ActiveRecord::Base.send :sanitize_sql_array, query

        if CryptKeeper.silence_logs?
          ::ActiveRecord::Base.logger.silence do
            execute_sql(query, new_transaction: new_transaction)
          end
        else
          execute_sql(query, new_transaction: new_transaction)
        end
      end

      # Private: Executes the query.
      #
      # query - the sql query
      # new_transaction - if the query should run inside a new transaction
      #
      # Returns an Array.
      def execute_sql(query, new_transaction: false)
        if new_transaction
          ::ActiveRecord::Base.transaction(requires_new: true) do
            ::ActiveRecord::Base.connection.execute(query).first
          end
        else
          ::ActiveRecord::Base.connection.execute(query).first
        end
      end
    end

    module DigestPassphrase
      # Private: Hash algorithm to use when generating a PBKDF2 passphrase.
      #
      # Returns a String.
      HASH_ALGORITHM = "sha512".freeze

      # Private: Iterations to use when generating a PBKDF2 passphrase.
      #
      # Returns a String.
      ITERATIONS = 5000

      private_constant :HASH_ALGORITHM, :ITERATIONS

      # Public: Iterations to use to generate digest passphrase.
      #
      # Returns a String.
      mattr_accessor :iterations do
        if iter = ENV["ARMOR_ITER"]
          warn :ARMOR_ITER unless iter == ITERATIONS
          Integer(iter)
        else
          ITERATIONS
        end
      end

      # Public: Generates a hex passphrase using the given key and salt.
      #
      # key  - Encryption key
      # salt - Encryption salt
      #
      # Returns a String.
      def digest_passphrase(key, salt)
        raise ArgumentError.new("Missing :key")  if key.blank?
        raise ArgumentError.new("Missing :salt") if salt.blank?

        require "openssl"

        digest = OpenSSL::Digest.new(hash_algorithm)

        hmac = OpenSSL::PKCS5.pbkdf2_hmac(
          key,
          salt,
          iterations,
          digest.digest_length,
          digest
        )

        hmac.unpack("H*").first
      end

      private

      # Private: Hash algorithm to use for digest passphrase.
      #
      # Returns a String.
      def hash_algorithm
        if hash = ENV["ARMOR_HASH"]
          warn :ARMOR_HASH unless hash == HASH_ALGORITHM
          hash
        else
          HASH_ALGORITHM
        end
      end

      # Private: Warns about the deprecated ENV vars used with the Armor gem.
      #
      # key - The ENV variable name
      #
      # Returns a String.
      def warn(key)
        require "active_support/deprecation"

        ActiveSupport::Deprecation.warn <<-MSG.squish
          CryptKeeper no longer uses the Armor gem to generate passphrases for
          MySQL AES encryption. Your installation is using a non-standard
          value for `ENV["#{key}"]` which affects the way passphrases are
          generated. You will need to re-encrypt your data with this variable
          removed prior to CryptKeeper v3.0.0.
        MSG
      end
    end
  end
end
