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
        filter      = /(pgp_sym_(encrypt|decrypt))\(((.|\n)*?)\)/i
        case_filter = /CASE\s\'.*\'\sWHEN/i

        event.payload[:sql] = event.payload[:sql].gsub(filter) do |_|
          "#{$1}([FILTERED])"
        end.gsub(case_filter) do |_|
          "CASE [FILTERED] WHEN"
        end

        sql_without_postgres_pgp(event)
      end
    end
  end
end

ActiveSupport.on_load :crypt_keeper_posgres_pgp_log do
  ActiveRecord::LogSubscriber.send :include, CryptKeeper::LogSubscriber::PostgresPgp
end
