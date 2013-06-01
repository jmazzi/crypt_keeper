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
      def encrypt(values)
        pgp_sym("pgp_sym_encrypt", Array(values).map { |v| v.to_s })
      end

      # Public: Decrypts a string
      #
      # Returns a plaintext string
      def decrypt(values)
        pgp_sym("pgp_sym_decrypt", Array(values))
      end

      private

      def pgp_sym(action, values)
        if values.empty?
          []
        else
          select = values.size.times.map do |i|
            "CASE ? WHEN NULL THEN NULL ELSE #{action}(?, ?) END AS value_#{i}"
          end.join(", ")

          args = values.map{ |value| [value, value, key] }.flatten

          escape_and_execute_sql(["SELECT #{select}", *args]).values
        end
      end
    end
  end
end
