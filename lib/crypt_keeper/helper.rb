module CryptKeeper
  module Helper
    module SQL
      private

      # Private: Sanitize an sql query and then execute it
      def escape_and_execute_sql(query)
        query = ::ActiveRecord::Base.send :sanitize_sql_array, query
        ::ActiveRecord::Base.connection.execute(query).first
      end
    end

    module Serializer
      def dump(value)
        encrypt(value)
      end

      def load(value)
        decrypt(value)
      end
    end
  end
end
