module CryptKeeper
  module Helper
    module SQL
      private

      # Private: Sanitize an sql query and then execute it.
      #
      # query - the sql query
      # new_transaction - if the query should run inside a new transaction
      #
      # Returns the ActiveRecord response.
      def escape_and_execute_sql(query, new_transaction: false)
        query = ::ActiveRecord::Base.send :sanitize_sql_array, query

        if CryptKeeper.silence_logs?
          ::ActiveRecord::Base.logger.silence do
            execute_sql(query, new_transaction: new_transaction)
          end
        else
          execute_sql(query, new_transaction: new_transaction)
        end
      end

      # Private: Executes the query.
      #
      # query - the sql query
      # new_transaction - if the query should run inside a new transaction
      #
      # Returns an Array.
      def execute_sql(query, new_transaction: false)
        if new_transaction
          ::ActiveRecord::Base.transaction(requires_new: true) do
            ::ActiveRecord::Base.connection.execute(query).first
          end
        else
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
