module CryptKeeper
  module Helper
    module SQL
      private

      # Private: Sanitize an sql query and then execute it
      def escape_and_execute_sql(query)
        query = ::ActiveRecord::Base.send :sanitize_sql_array, query
        ::ActiveRecord::Base.connection.select_one(query)
      end
    end
  end
end
