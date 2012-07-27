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

Use can see an AES example here [here](https://github.com/jmazzi/crypt_keeper_providers/blob/master/lib/crypt_keeper_providers/aes.rb)

## Why?

The options available were either too complicated under the hood or had weird 
edge cases that made the library hard to use. I wanted to write something
simple that *just works*.

## Usage

```ruby

class MyModel < ActiveRecord::Base
  crypt_keeper :field, :other_field, encryptor: CryptKeeperProviders::Aes, 
    passphrase: 'super_good_password'
end

model = MyModel.new(field: 'sometext')
model.save! #=> Your data is now encrypted
model.field #=> 'sometext'

```

It works with all persistences methods: `update_attribute`, `update_attributes`,
and save.

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
