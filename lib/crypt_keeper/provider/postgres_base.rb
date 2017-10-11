require 'crypt_keeper/log_subscriber/postgres_pgp'

module CryptKeeper
  module Provider
    class PostgresBase < Base
      include CryptKeeper::Helper::SQL
      include CryptKeeper::LogSubscriber::PostgresPgp

      INVALID_DATA_ERROR = "Wrong key or corrupt data".freeze

      # Public: Checks if value is already encrypted.
      #
      # Returns boolean
      def encrypted?(value)
        begin
          escape_and_execute_sql([
            "SELECT pgp_key_id(?)", value.to_s
          ])['pgp_key_id'].present?
        rescue ActiveRecord::StatementInvalid => e
          if e.message.include?(INVALID_DATA_ERROR)
            false
          else
            raise
          end
        end
      end
    end
  end
end
