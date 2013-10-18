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
        if value.blank?
          value
        else
          encrypt(value)
        end
      end

      def load(value)
        if value.blank?
          value
        else
          decrypt(value)
        end
      end
    end
  end
end
