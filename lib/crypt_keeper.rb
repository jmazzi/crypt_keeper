require 'active_record'

require 'crypt_keeper/version'
require 'crypt_keeper/model'

require 'crypt_keeper/provider/aes'
require 'crypt_keeper/provider/mysql_aes'
require 'crypt_keeper/provider/postgres_pgp'

module CryptKeeper
end

ActiveSupport.on_load :active_record do
  include CryptKeeper::Model
end
