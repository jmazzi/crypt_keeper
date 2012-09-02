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
        filter = /(aes_(encrypt|decrypt))\(((.|\n)*?)\)/i

        event.payload[:sql] = event.payload[:sql].gsub(filter) do |_|
          "#{$1}([FILTERED])"
        end

        sql_without_mysql_aes(event)
      end
    end
  end
end

ActiveSupport.on_load :active_record do
  ActiveRecord::LogSubscriber.send :include, CryptKeeper::LogSubscriber::MysqlAes
end
