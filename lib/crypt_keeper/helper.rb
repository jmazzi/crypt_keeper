module CryptKeeper
  module Helper
    module SQL
      private

      # Private: Sanitize an sql query and then execute it.
      #
      # query - the sql query
      #
      # Returns the ActiveRecord response.
      def escape_and_execute_sql(query)
        query = ::ActiveRecord::Base.send :sanitize_sql_array, query

        if CryptKeeper.silence_logs?
          ::ActiveRecord::Base.logger.silence do
            execute_sql(query)
          end
        else
          execute_sql(query)
        end
      end

      # Private: Executes the query.
      #
      # query - the sql query
      #
      # Returns an Array.
      def execute_sql(query)
        ::ActiveRecord::Base.transaction(requires_new: true) do
          ::ActiveRecord::Base.connection.execute(query).first
        end
      end
    end

    module DigestPassphrase
      def digest_passphrase(key, salt)
        raise ArgumentError.new("Missing :key") if key.blank?
        raise ArgumentError.new("Missing :salt") if salt.blank?
        ::Armor.digest(key, salt)
      end
    end
  end
end
