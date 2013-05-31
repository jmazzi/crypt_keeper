require 'active_record'
require 'logger'

::ActiveRecord::Base.logger = Logger.new SPEC_ROOT.join('debug.log').to_s
::ActiveRecord::Migration.verbose = false

module CryptKeeper
  class SensitiveData < ActiveRecord::Base; end

  module ConnectionHelpers
    def use_postgres
      before :all do
        ::ActiveRecord::Base.clear_active_connections!
        config = YAML.load_file SPEC_ROOT.join('database.yml')
        ::ActiveRecord::Base.establish_connection(config['postgres'])
      end
    end

    def use_mysql
      before :all do
        ::ActiveRecord::Base.clear_active_connections!
        config = YAML.load_file SPEC_ROOT.join('database.yml')
        ::ActiveRecord::Base.establish_connection(config['mysql'])
      end
    end

    def use_sqlite
      before :all do
        ::ActiveRecord::Base.clear_active_connections!
        ::ActiveRecord::Base.establish_connection(:adapter => 'sqlite3',
          :database => ':memory:')

        ::ActiveRecord::Schema.define do
          create_table :sensitive_data, :force => true do |t|
            t.column :name, :string
            t.column :storage, :text
            t.column :secret, :text
          end
        end
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
