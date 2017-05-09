require 'crypt_keeper/log_subscriber/postgres_pgp'

module CryptKeeper
  module Provider
    class PostgresBase < Base
      private

      # Private: Sanitize an sql query and then execute it
      #
      # query - the prepared statement query
      # binds - a hash of binds of values for the prepared statement. Example:
      #         { "value" => "thevalue", "key" => "thekey" }
      #
      # Returns the response.
      def escape_and_execute_sql(query, binds)
        prepared_statement_binds = binds.map do |k, v|
          ActiveRecord::Relation::QueryAttribute.new(k, v, ActiveModel::Type::String.new)
        end

        ::ActiveRecord::Base.connection.exec_query(query, nil, prepared_statement_binds).first
      end
    end
  end
end
