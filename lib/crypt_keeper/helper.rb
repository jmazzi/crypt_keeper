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

    module DigestPassphrase
      def digest_passphrase(key, salt)
        raise ArgumentError.new("Missing :key") if key.blank?
        raise ArgumentError.new("Missing :salt") if salt.blank?
        ::Armor.digest(key, salt)
      end
    end

    module Serializer
      def dump(value)
        if value.blank?
          value
        else
          encrypt(value.to_s)
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
