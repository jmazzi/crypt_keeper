require 'active_support/concern'
require 'active_support/lazy_load_hooks'

module CryptKeeper
  module LogSubscriber
    module MysqlAes
      extend ActiveSupport::Concern

      included do
        alias_method_chain :sql, :mysql_aes
      end

      # Public: Prevents sensitive data from being logged
      def sql_with_mysql_aes(event)
        # Also filter from_base64 in case user-constructed queries include that
        filter = /(aes_(encrypt|decrypt))\((from_base64\(.*\))?.*\)/i

        event.payload[:sql] = event.payload[:sql].encode('UTF-8', 'UTF-8', :invalid => :replace).gsub(filter) do |_|
          "#{$1}([FILTERED])"
        end

        sql_without_mysql_aes(event)
      end
    end
  end
end

ActiveSupport.on_load :crypt_keeper_mysql_aes_log do
  ActiveRecord::LogSubscriber.send :include, CryptKeeper::LogSubscriber::MysqlAes
end
