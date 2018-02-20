[![Build Status](https://secure.travis-ci.org/jmazzi/crypt_keeper.png?branch=master)](http://travis-ci.org/jmazzi/crypt_keeper) [![Gem Version](https://badge.fury.io/rb/crypt_keeper.svg)](http://badge.fury.io/rb/crypt_keeper)

![CryptKeeper](http://i.imgur.com/qf0aD.jpg)

# CryptKeeper

Provides transparent encryption for ActiveRecord. It is encryption agnostic.
You can guard your data with any encryption algorithm you want. All you need
is a simple class that does 3 things.

1. Takes a hash argument for `initialize`
2. Provides an `encrypt` method that returns the encrypted string
3. Provides a `decrypt` method that returns the plaintext

Note: Any options defined using `crypt_keeper` will be passed to `new` as a
hash.

You can see an example [here](https://github.com/jmazzi/crypt_keeper/blob/master/lib/crypt_keeper/provider/active_support.rb).

## Why?

The options available were either too complicated under the hood or had weird
edge cases that made the library hard to use. I wanted to write something
simple that *just works*.

## Usage

```ruby
class MyModel < ActiveRecord::Base
  crypt_keeper :field, :other_field, encryptor: :active_support, key: 'super_good_password', salt: 'salt'
end

model = MyModel.new(field: 'sometext')
model.save! #=> Your data is now encrypted
model.field #=> 'sometext'
```

It works with all persistences methods: `update_attributes`, `create`, `save`
etc.

Note: `update_attribute` is deprecated in ActiveRecord 3.2.7. It is superseded
by [update_column](http://apidock.com/rails/ActiveRecord/Persistence/update_column)
which _skips_ all validations, callbacks.

That means using `update_column` will not perform any encryption. This is
expected behavior, and has its use cases. An example would be migrating from
one type of encryption to another. Using `update_column` would allow you to
update the content without going through the current encryptor.

## Generating Keys/Salts

For encryptors requiring secret keys/salts, you can generate them via
`rails secret`:

```
rails secret
ef209071bd76143a75eda57b99425da63ce6c2d44581d652aa4302a90dcd7d7e99cbc22091c01a19f93ea484f40b142612f9bf76de8eb2d51ff9b3eb02a7782c
```

Or manually (this is the same implementation that Rails uses):

```
ruby -e "require 'securerandom'; puts SecureRandom.hex(64)"
```

These values should be stored outside of your application repository for added
security. For example, one could use [dotenv][] and reference them as `ENV`
variables.

```
# .env
CRYPT_KEEPER_KEY=75d942f3d3b3492772e0330f717eaf5e689673ea8b983475ef8f6551f6e99d280cd89972706e46b48240cc01c4d0f7df5ffa3524566b789d147ed04cc4ea4eab
CRYPT_KEEPER_SALT=b16a153e99a5db616a861ea5a6febc64d8a758c4aef3b8c8fc6675ac9daf03f7965f16e8b4b2bdfd28ff65f5203afb8102b8f41c514c3667bb3512015b1e77e8
```

Then in your model:

```ruby
class MyModel < ActiveRecord::Base
  crypt_keeper :field, :other_field, encryptor: :active_support, key: ENV["CRYPT_KEEPER_KEY"], salt: ENV["CRYPT_KEEPER_SALT"]
end
```

[dotenv]: https://github.com/bkeepers/dotenv

## Encodings

You can force an encoding on the plaintext before encryption and after decryption by using the `encoding` option. This is useful when dealing with multibyte strings:

```ruby
class MyModel < ActiveRecord::Base
  crypt_keeper :field, :other_field, encryptor: :active_support, key: 'super_good_password', salt: 'salt', encoding: 'UTF-8'
end

model = MyModel.new(field: 'Tromsø')
model.save! #=> Your data is now encrypted
model.field #=> 'Tromsø'
model.field.encoding #=> #<Encoding:UTF-8>
```

## Adding encryption to an existing table

If you are working with an existing table you would like to encrypt, you must use the `MyExistingModel.encrypt_table!` class method.

```ruby
class MyExistingModel < ActiveRecord::Base
  crypt_keeper :field, :other_field, encryptor: :active_support, key: 'super_good_password', salt: 'salt'
end

MyExistingModel.encrypt_table!
```

Running `encrypt_table!` will encrypt all rows in the database using the encryption method specificed by the `crypt_keeper` line in your model.

## Supported Available Encryptors

There are four supported encryptors: `active_support`, `mysql_aes_new`, `postgres_pgp`, `postgres_pgp_public_key`.

* [ActiveSupport](https://github.com/jmazzi/crypt_keeper/blob/master/lib/crypt_keeper/provider/active_support.rb)
  * Encryption is performed using [ActiveSupport::MessageEncryptor](http://api.rubyonrails.org/classes/ActiveSupport/MessageEncryptor.html)
  * Passphrases are derived using [PBKDF2](http://en.wikipedia.org/wiki/PBKDF2)

* [MySQL AES New](https://github.com/jmazzi/crypt_keeper/blob/master/lib/crypt_keeper/provider/mysql_aes_new.rb)
  * Encryption is peformed MySQL's native AES functions.
  * ActiveRecord logs are [automatically](https://github.com/jmazzi/crypt_keeper/blob/master/lib/crypt_keeper/log_subscriber/mysql_aes.rb)
    filtered for you to protect sensitive data from being logged.
  * Passphrases are derived using [PBKDF2](http://en.wikipedia.org/wiki/PBKDF2)

* [PostgreSQL PGP](https://github.com/jmazzi/crypt_keeper/blob/master/lib/crypt_keeper/provider/postgres_pgp.rb).
  * Encryption is performed using PostgresSQL's native [PGP functions](http://www.postgresql.org/docs/9.1/static/pgcrypto.html).
  * It requires the `pgcrypto` PostgresSQL extension:
    `CREATE EXTENSION IF NOT EXISTS pgcrypto`
  * ActiveRecord logs are [automatically](https://github.com/jmazzi/crypt_keeper/blob/master/lib/crypt_keeper/log_subscriber/postgres_pgp.rb)
    filtered for you to protect senitive data from being logged.
  * Custom options can be set through the `:pgcrypto_options`. E.g. `crypt_keeper :field, encryptor: :postgres_pgp, pgcrypto_options: 'compress-level=9'
  * Passphrases are hashed by PostgresSQL itself using a [String2Key (S2K)](http://www.postgresql.org/docs/9.2/static/pgcrypto.html) algorithm. This is rather similar to crypt() algorithms — purposefully slow and with random salt — but it produces a full-length binary key.

* [PostgreSQL PGP Public Key](https://github.com/jmazzi/crypt_keeper/blob/master/lib/crypt_keeper/provider/postgres_pgp_public_key.rb).
  * Encryption is performed using PostgresSQL's native [PGP functions](http://www.postgresql.org/docs/9.1/static/pgcrypto.html).
  * It requires the `pgcrypto` PostgresSQL extension:
    `CREATE EXTENSION IF NOT EXISTS pgcrypto`
  * ActiveRecord logs are [automatically](https://github.com/jmazzi/crypt_keeper/blob/master/lib/crypt_keeper/log_subscriber/postgres_pgp.rb)
    filtered for you to protect senitive data from being logged.
  * Accepts a public and private_key. The private key is optional. If the private key is not present the ciphertext value is returned instead of the plaintext. This allows you to keep the private key off certain servers. Encryption is possible with only a public key. Any server that needs access to the plaintext will need the private key.
  * Passphrases are hashed by PostgresSQL itself using a [String2Key (S2K)](http://www.postgresql.org/docs/9.2/static/pgcrypto.html) algorithm. This is rather similar to crypt() algorithms — purposefully slow and with random salt — but it produces a full-length binary key.

## Searching
Searching ciphertext is a complex problem that varies depending on the encryption algorithm you choose. All of the bundled providers include search support, but they have some caveats.

* ActiveSupport::MessageEncryptor
  * ActiveSupport's MessageEncryptor uses a random initialization vector when generating keys. The same plaintext encrypted multiple times will have different output each time for the ciphertext. Since this is the case, it is not possible to search leveraging the database. Database rows will need to be filtered in memory. It is suggested that you use a scope or ActiveRecord batches to narrow the results before seaching them.

* Mysql AES
 * Surprisingly, MySQL's implementation of AES does not use a random initialization vector. The column containing the ciphertext can be indexed and searched quickly.

* PostgresSQL PGP
 * PGP also uses a random initialization vector which means it generates unique output each time you encrypt plaintext. Although the database can be searched by performing row level decryption and comparing the plaintext, it will not be able to use an index. A scope or batch is suggested when searching.

## How the search interface is used

```ruby
Model.search_by_plaintext(:field, 'searchstring')
# With a scope
Model.where(something: 'blah').search_by_plaintext(:field, 'searchstring')
```

## Creating your own encryptor

Creating your own encryptor is easy. All you have to do is create a class
under the `CryptKeeper::Provider` namespace, and inherit from the `Base` encryptor,
like this:

```ruby
module CryptKeeper
  module Provider
    class MyEncryptor < Base
      def initialize(options = {})
      end

      def encrypt(value)
      end

      def decrypt(value)
      end
    end
  end
end

```

Just require your code and setup your model to use it. Just pass the class name
as a string or an underscored symbol

```ruby
class MyModel < ActiveRecord::Base
  crypt_keeper :field, :other_field, encryptor: :my_encryptor, key: 'super_good_password'
end
```

## Migrating from CryptKeeper 1.x to 2.0

CryptKeeper 2.0 removes the AES encryptor due to security issues in the
underlying AES gem. If you were previously using the `aes_new` encryptor, you
will need to follow these instructions to reencrypt your data.

The general migration path is as follows:

1. Enable maintenance mode in any live apps
2. Backup database
3. Decrypt tables: TableName.decrypt_table!
4. Update to 2.0.0.rc1 in your app. Update the encryptor to use :active_support
5. Encrypt tables: `TableName.encrypt_table!`
6. Verify data can be decrypted: `TableName.first`
7. Disable maintenance mode if necessary

In case you experience problems, the rollback procedure is as follows:

1. Enable maintenance mode
2. Backup database again
3. Restore first database dump, from before CryptKeeper 2.0.0.rc1
4. Verify data can be decrypted
5. Disable maintenance mode
6. Let us know what happened :(

## Requirements

CryptKeeper has been tested against ActiveRecord 4.2 and 5.0 using Ruby
2.1.10, 2.2.5 and 2.3.1.

ActiveRecord 4.2 is supported starting with v0.19.0.
ActiveRecord 5.0 is supported starting with v0.23.0.

## Installation

Add this line to your application's Gemfile:

    gem 'crypt_keeper'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install crypt_keeper


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
