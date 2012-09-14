require 'crypt_keeper/log_subscriber/postgres_pgp_pub_key'

module CryptKeeper
  module Provider
    class PostgresPgpPubKey
      attr_accessor :public_key, :private_key, :password

      # Public: Initializes the encryptor
      #
      #  options - A hash, :public_key is required
      #
      # NOTE:
      #  :public_key and :private_key are expected to be in ASCII Armor format
      #  see: http://tools.ietf.org/html/rfc4880#section-6.2
      #
      # EXAMPLES:
      #  Encrypt & Decrypt (standard mode:
      #   PostgresPgpPubKey.new public_key: pub, private_key: priv
      #   - or -
      #   PostgresPgpPubKey.new public_key: pub, private_key: priv, password: psswd
      #
      #  Encrypt-only (pass-through mode):
      #   PostgresPgpPubKey.new public_key: pub
      #   NOTE:
      #    'Pass-through mode' is convenient for storage of asymmetrically-encrypted
      #    data within the database. When :private_key is not provided, the
      #    encrypted data will be 'passed-through' in the #decrypt method.
      #    This mode allows for offline decryption of data.
      def initialize(options = {})
        @public_key = options.fetch(:public_key) do
          raise ArgumentError, "Missing :public_key"
        end
        # :private_key and :password are not required (pass-through mode)
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
      # Returns:
      #   If :private_key HAS been set, returns a plaintext string
      #   If :private_key HAS NOT been set, return encrypted bytes (pass-through mode)
      def decrypt(value)
        return value if private_key == nil
        if password
          escape_and_execute_sql(["SELECT pgp_pub_decrypt(?, dearmor(?), ?)", value, private_key, password])['pgp_pub_decrypt']
        else
          escape_and_execute_sql(["SELECT pgp_pub_decrypt(?, dearmor(?))", value, private_key])['pgp_pub_decrypt']
        end
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
