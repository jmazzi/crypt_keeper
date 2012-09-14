require 'crypt_keeper/log_subscriber/postgres_pgp_pub_key'

module CryptKeeper
  module Provider
    class PostgresPgpPubKey
      attr_accessor :public_key, :private_key, :password

      # Public: Initializes the encryptor
      #
      #  options - A hash, :public_key is required
      def initialize(options = {})
        @public_key = options.fetch(:public_key) do
          raise ArgumentError, "Missing :public_key"
        end
        @private_key, @password = options.fetch(:private_key, nil),
                                  options.fetch(:password, nil)
        raise ArgumentError, "Provided :password but missing :private_key" if password && private_key.blank?
      end

      # Public: Encrypts a string
      #
      # Returns an encrypted string
      def encrypt(value)
        escape_and_execute_sql(["SELECT pgp_pub_encrypt(?, dearmor(?))", value, public_key])['pgp_pub_encrypt']
      end

      # Public: Decrypts a string
      #
      # Returns a plaintext string if :private_key is present and
      #         the encrypted value if :private_key is not present
      def decrypt(value)
        return value if private_key == nil
        escape_and_execute_sql(["SELECT pgp_pub_decrypt(?, dearmor(?), ?)", value, private_key, password])['pgp_pub_decrypt']
      end

      private

      # Private: Sanitize an sql query and then execute it
      def escape_and_execute_sql(query)
        query = ::ActiveRecord::Base.send :sanitize_sql_array, query
        ::ActiveRecord::Base.connection.execute(query).first
      end
    end
  end
end
