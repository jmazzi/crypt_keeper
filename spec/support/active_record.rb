require 'active_record'
require 'logger'

::ActiveRecord::Base.logger = Logger.new SPEC_ROOT.join('debug.log').to_s
::ActiveRecord::Migration.verbose = false

module CryptKeeper
  class SensitiveDataMysql < ActiveRecord::Base
    self.table_name = 'sensitive_data'
    crypt_keeper :storage, key: 'tool', encryptor: :mysql_aes
  end

  class SensitiveDataPg < ActiveRecord::Base
    self.table_name = 'sensitive_data'
    crypt_keeper :storage, key: 'tool', encryptor: :postgres_pgp
  end

  class SensitiveData < ActiveRecord::Base
  end

  module ConnectionHelpers
    class CreateConnection
      def initialize(driver)
        @driver = driver
        @config = YAML.load_file SPEC_ROOT.join('database.yml')
        connect!
      end

      def define_schema!
        ::ActiveRecord::Schema.define do
          create_table :sensitive_data, :force => true do |t|
            t.column :name, :string
            t.column :storage, :text
            t.column :secret, :text
          end
        end
      end

      private
      def connect!
        ::ActiveRecord::Base.establish_connection(@config[@driver])
      end
    end

    def use_postgres
      before :each do
        CreateConnection.new('postgres').define_schema!
      end
    end

    def use_mysql
      before :each do
        CreateConnection.new('mysql').define_schema!
      end
    end

    def use_sqlite
      before :all do
        CreateConnection.new('sqlite').define_schema!
      end
    end
  end
end

module LoggedQueries
  # Logs the queries run inside the block, and return them.
  def logged_queries(&block)
    queries = []

    subscriber = ActiveSupport::Notifications
      .subscribe('sql.active_record') do |name, started, finished, id, payload|
      queries << payload[:sql]
    end

    block.call

    queries

    ensure ActiveSupport::Notifications.unsubscribe(subscriber)
  end
end

RSpec.configure do |config|
  config.extend CryptKeeper::ConnectionHelpers
  config.include LoggedQueries
end
