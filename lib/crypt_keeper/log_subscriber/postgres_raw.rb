require 'active_support/concern'
require 'active_support/lazy_load_hooks'

module CryptKeeper
  module LogSubscriber
    module PostgresRaw
      extend ActiveSupport::Concern

      included do
        alias_method_chain :sql, :postgres_raw
      end

      # Public: Prevents sensitive data from being logged
      def sql_with_postgres_raw(event)
        filter  = /(encode\()*(\(*)(?<operation>decrypt|encrypt)(_iv)*(\(+.*\)+)/im
        payload = event.payload[:sql]
                    .encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
        return if CryptKeeper.silence_logs? && payload =~ filter
        event.payload[:sql] = payload.gsub(filter) do |_|
          "#{$~[:operation]}([FILTERED])"
        end

        sql_without_postgres_raw(event)
      end
    end
  end
end

ActiveSupport.on_load :crypt_keeper_postgres_raw_log do
  ActiveRecord::LogSubscriber.send :include, CryptKeeper::LogSubscriber::PostgresRaw
end
