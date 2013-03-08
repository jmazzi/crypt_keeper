require 'active_record'
require 'logger'

::ActiveRecord::Base.logger = Logger.new SPEC_ROOT.join('debug.log').to_s
::ActiveRecord::Migration.verbose = false

module CryptKeeper
  class SensitiveData < ActiveRecord::Base; end

  module ConnectionHelpers
    def use_postgres(define_schema = false)
      before :all do
        ::ActiveRecord::Base.clear_active_connections!
        config = YAML.load_file SPEC_ROOT.join('database.yml')
        ::ActiveRecord::Base.establish_connection(config['postgres'])

        ::ActiveRecord::Schema.define do
          create_table :sensitive_data, :force => true do |t|
            t.column :name, :string
            t.column :storage, :text
            t.column :secret, :text
          end
        end if define_schema
      end
    end

    def use_mysql(define_schema = false)
      before :all do
        ::ActiveRecord::Base.clear_active_connections!
        config = YAML.load_file SPEC_ROOT.join('database.yml')
        ::ActiveRecord::Base.establish_connection(config['mysql'])

        ::ActiveRecord::Schema.define do
          create_table :sensitive_data, :force => true do |t|
            t.column :name, :string
            t.column :storage, :text
            t.column :secret, :text
          end
        end if define_schema
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

RSpec.configure do |config|
  config.extend CryptKeeper::ConnectionHelpers
end
