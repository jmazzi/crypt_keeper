module CryptKeeper
  module Helper
    module SQL
      private

      # Private: Sanitize an sql query and then execute it
      def escape_and_execute_sql(query)
        ::ActiveRecord::Base.connection.execute(escape_sql(query)).first
      end
      
      # Private: Sanitize an sql query
      def escape_sql(query)
        ::ActiveRecord::Base.send :sanitize_sql_array, query
      end
    end
  end
end
