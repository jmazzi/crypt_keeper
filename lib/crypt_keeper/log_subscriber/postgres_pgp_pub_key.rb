require 'active_support/concern'
require 'active_support/lazy_load_hooks'

module CryptKeeper
  module LogSubscriber
    module PostgresPgpPubKey
      extend ActiveSupport::Concern

      included do
        alias_method_chain :sql, :postgres_pgp_pub_key
      end

      # Public: Prevents sensitive data from being logged
      def sql_with_postgres_pgp_pub_key(event)
        # this is a very aggressive regular expression due to variety of
        # ASCII Armor character sequences
        filter = /(pgp_pub_encrypt|pgp_pub_decrypt).*/mix

        event.payload[:sql] = event.payload[:sql].gsub(filter) do |_|
          "#{$1}([FILTERED])"
        end

        sql_without_postgres_pgp_pub_key(event)
      end
    end
  end
end

ActiveSupport.on_load :active_record do
  ActiveRecord::LogSubscriber.send :include, CryptKeeper::LogSubscriber::PostgresPgpPubKey
end
