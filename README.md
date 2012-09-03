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

You can see an AES example [here](/jmazzi/crypt_keeper/blob/master/lib/crypt_keeper/provider/aes.rb).

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

There are two included encryptors.

* [AES](https://github.com/jmazzi/crypt_keeper/blob/master/lib/crypt_keeper/provider/aes.rb)
  * Encryption is peformed using AES-256 via OpenSSL.


* [MySQL AES](https://github.com/jmazzi/crypt_keeper/blob/master/lib/crypt_keeper/provider/mysql_aes.rb)
  * Encryption is peformed MySQL's native AES functions.


* [PostgreSQL PGP](https://github.com/jmazzi/crypt_keeper/blob/master/lib/crypt_keeper/provider/postgres_pgp.rb).
  * Encryption is performed using PostgresSQL's native [PGP functions](http://www.postgresql.org/docs/9.1/static/pgcrypto.html).
  * It requires the `pgcrypto` PostgresSQL extension:
    `CREATE EXTENSION IF NOT EXISTS pgcrypto`
  * ActiveRecord logs are [automatically](https://github.com/jmazzi/crypt_keeper/blob/master/lib/crypt_keeper/log_subscriber/postgres_pgp.rb)
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
