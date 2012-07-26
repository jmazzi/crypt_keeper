require 'active_record'
require 'logger'

ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => ':memory:')
ActiveRecord::Base.logger       = Logger.new SPEC_ROOT.join 'debug.log'
ActiveRecord::Migration.verbose = false

ActiveRecord::Schema.define do
  create_table :sensitive_data, :force => true do |t|
    t.column :name, :string
    t.column :storage, :text
    t.column :secret, :text
  end
end

class SensitiveData < ActiveRecord::Base; end
