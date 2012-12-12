[![Build Status](https://secure.travis-ci.org/jmazzi/crypt_keeper.png?branch=master)](http://travis-ci.org/jmazzi/crypt_keeper)

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

You can see an AES example [here](https://github.com/jmazzi/crypt_keeper/blob/master/lib/crypt_keeper/provider/aes.rb).

## Why?

The options available were either too complicated under the hood or had weird
edge cases that made the library hard to use. I wanted to write something
simple that *just works*.

## Usage

```ruby
class MyModel < ActiveRecord::Base
  crypt_keeper :field, :other_field, :encryptor => :aes, :key => 'super_good_password'
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

### Using the PostgreSQL PGP Public-Key Encryptor/Decyptor

**NOTE:** `:public_key` and `:private_key` are expected to be in ASCII Armor format.

**Encrypt/Decrypt Mode:**

```ruby
class MyModel < ActiveRecord::Base
  crypt_keeper :field, :other_field, encryptor: :postgres_pgp_pub_key,
                                     public_key: File.join(RAILS_ROOT,'config','public.key'),
                                     private_key: File.join(RAILS_ROOT,'config','private.key'),
                                     password: SampleApp:Application.config.pgp_password
end

model = MyModel.new(field: 'sometext')
model.save! #=> Your data is now encrypted.
model.field #=> 'sometext'
```

**Encrypt-only Mode w/ Pass-through Decryption:**

The 'Encrypt-only Mode' allows for ultra-secure storage of data in the database.
Since there is no way to decrypt the data within the app (no storage of private
key), it's ideally-suited for storing personal data (e.g. SSNs, CC#s, etc).

Decryption of data would happen outside of the app (i.e. desktop app, intranet
web application, etc).

```ruby
class MyModel < ActiveRecord::Base
  crypt_keeper :field, :other_field, encryptor: :postgres_pgp_pub_key,
                                     public_key: File.join(RAILS_ROOT,'config','public.key')

  # not required, but allows for easy transfer of encrypted bytes:
  def field64
    Base64.strict_encode64(field)
  end
end

model = MyModel.new(field: 'sometext')
model.save!   #=> Your data is now encrypted.
model.field   #=> '\\x..................'
model.field64 #=> Base64-encoded version of encrypted text
```
**NOTE:** To use PostgreSQL's PGP functions, you must enable the `pgcrypto`
extension for the database(s) in your application:

```
$ psql database_name

database_name=# CREATE EXTENSION pgcrypto;
```

## Creating your own encryptor

Creating your own encryptor is easy. All you have to do is create a class
under the `CryptKeeper::Provider` namespace, like this:

```ruby
module CryptKeeper
  module Provider
    class MyEncryptor
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
  crypt_keeper :field, :other_field, :encryptor => :my_encryptor, :key => 'super_good_password'
end
```

## Available Encryptors

There are four (4) included encryptors:

- [AES](https://github.com/jmazzi/crypt_keeper/blob/master/lib/crypt_keeper/provider/aes.rb)
  * Encryption is peformed using AES-256 via OpenSSL.

- [MySQL AES](https://github.com/jmazzi/crypt_keeper/blob/master/lib/crypt_keeper/provider/mysql_aes.rb)
  * Encryption is peformed MySQL's native AES functions.
  * ActiveRecord logs are [automatically](https://github.com/jmazzi/crypt_keeper/blob/master/lib/crypt_keeper/log_subscriber/mysql_aes.rb)
    filtered for you to protect senitive data from being logged.

- [PostgreSQL PGP Symmetric-Key Encryption](https://github.com/jmazzi/crypt_keeper/blob/master/lib/crypt_keeper/provider/postgres_pgp.rb).
  * Encryption is performed using PostgresSQL's native [PGP symmetric-key functions](http://www.postgresql.org/docs/9.1/static/pgcrypto.html#AEN136344).
  * It requires the `pgcrypto` PostgresSQL extension:

    `CREATE EXTENSION IF NOT EXISTS pgcrypto`

  * ActiveRecord logs are [automatically](https://github.com/jmazzi/crypt_keeper/blob/master/lib/crypt_keeper/log_subscriber/postgres_pgp.rb)
    filtered for you to protect senitive data from being logged.

- [PostgreSQL PGP Public-Key Encryption](https://github.com/jmazzi/crypt_keeper/blob/master/lib/crypt_keeper/provider/postgres_pgp_pub_key.rb).
  * Encryption is performed using PostgresSQL's native [PGP asymmetrical public-key functions](http://www.postgresql.org/docs/9.1/static/pgcrypto.html#AEN136363).
  * It requires the `pgcrypto` PostgresSQL extension:

    `CREATE EXTENSION IF NOT EXISTS pgcrypto`

  * ActiveRecord logs are [automatically](https://github.com/jmazzi/crypt_keeper/blob/master/lib/crypt_keeper/log_subscriber/postgres_pgp_pub_key.rb)
    filtered for you to protect senitive data from being logged.

## Requirements

CryptKeeper has been tested against ActiveRecord 3.0, 3.1, and 3.2 using ruby
1.9.2, 1.9.3 and jruby in 1.9 mode.

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
