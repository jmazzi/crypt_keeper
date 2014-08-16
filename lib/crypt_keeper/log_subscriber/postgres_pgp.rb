require 'active_support/concern'
require 'active_support/lazy_load_hooks'

module CryptKeeper
  module LogSubscriber
    module PostgresPgp
      extend ActiveSupport::Concern

      included do
        alias_method_chain :sql, :postgres_pgp
      end

      # Public: Prevents sensitive data from being logged
      def sql_with_postgres_pgp(event)
        filter  = /(\(*)pgp_(sym|pub)_(?<operation>decrypt|encrypt)(\(+.*\)+)/im
        payload = event.payload[:sql]
          .encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')

        event.payload[:sql] = payload.gsub(filter) do |_|
          "#{$~[:operation]}([FILTERED])"
        end

        sql_without_postgres_pgp(event)
      end
    end
  end
end

ActiveSupport.on_load :crypt_keeper_postgres_pgp_log do
  ActiveRecord::LogSubscriber.send :include, CryptKeeper::LogSubscriber::PostgresPgp
end
