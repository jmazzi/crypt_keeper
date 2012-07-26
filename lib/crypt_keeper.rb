require 'crypt_keeper/version'
require 'crypt_keeper/model'
require 'active_record'

module CryptKeeper
end

ActiveSupport.on_load(:active_record) do
  include CryptKeeper::Model
end
