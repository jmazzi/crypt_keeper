require 'crypt_keeper/log_subscriber/postgres_pgp'

module CryptKeeper
  module Provider
    class PostgresBase < Base
      include CryptKeeper::Helper::SQL
      include CryptKeeper::LogSubscriber::PostgresPgp

      # Public: Checks if value is already encrypted.
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
