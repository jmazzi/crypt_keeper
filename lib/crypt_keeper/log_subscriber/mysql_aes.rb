require 'active_support/concern'
require 'active_support/lazy_load_hooks'

module CryptKeeper
  module LogSubscriber
    module MysqlAes
      # Public: Prevents sensitive data from being logged
      #
      # event - An ActiveSupport::Notifications::Event
      #
      # Returns a boolean.
      def sql(event)
        filter  = /(aes_(encrypt|decrypt))\(.*\)/i
        payload = event.payload[:sql]
          .encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')

        return if CryptKeeper.silence_logs? && payload =~ filter

        event.payload[:sql] = payload.gsub(filter) do |_|
          "#{$1}([FILTERED])"
        end

        super(event)
      end
    end
  end
end

ActiveSupport.on_load :crypt_keeper_mysql_aes_log do
  ActiveRecord::LogSubscriber.prepend CryptKeeper::LogSubscriber::MysqlAes
end
