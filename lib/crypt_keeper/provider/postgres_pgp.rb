require 'crypt_keeper/log_subscriber/postgres_pgp'

module CryptKeeper
  module Provider
    class PostgresPgp
      include CryptKeeper::Helper::SQL
      attr_accessor :key

      # Public: Initializes the encryptor
      #
      #  options - A hash, :key is required
      def initialize(options = {})
        ActiveSupport.run_load_hooks(:crypt_keeper_posgres_pgp_log, self)

        @key = options.fetch(:key) do
          raise ArgumentError, "Missing :key"
        end
      end

      # Public: Encrypts a string
      #
      # Returns an encrypted string
      def encrypt(value)
        escape_and_execute_sql(["SELECT pgp_sym_encrypt(?, ?)", value.to_s, key])['pgp_sym_encrypt']
      end

      # Public: Decrypts a string
      #
      # Returns a plaintext string
      def decrypt(values)
        values = Array(values)

        select = values.size.times.map do |i|
          "CASE ? WHEN NULL THEN NULL ELSE pgp_sym_decrypt(?, ?) END AS decrypt_#{i}"
        end.join(", ")

        args = values.map{ |value| [value, value, key] }.flatten

        escape_and_execute_sql(["SELECT #{select}", *args]).values
      end
    end
  end
end
