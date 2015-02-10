# -*- encoding: utf-8 -*-
require File.expand_path('../lib/crypt_keeper/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Justin Mazzi"]
  gem.email         = ["jmazzi@gmail.com"]
  gem.description   = %q{Transparent ActiveRecord encryption}
  gem.summary       = gem.description
  gem.homepage      = "http://jmazzi.github.com/crypt_keeper/"
  gem.license       = 'MIT'

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "crypt_keeper"
  gem.require_paths = ["lib"]
  gem.version       = CryptKeeper::VERSION

  gem.add_runtime_dependency 'activerecord',  '>= 3.1', '< 4.3'
  gem.add_runtime_dependency 'activesupport', '>= 3.1', '< 4.3'
  gem.add_runtime_dependency 'aes',           '~> 0.5.0'
  gem.add_runtime_dependency 'armor',         '~> 0.0.2'

  gem.add_development_dependency 'rspec',       '~> 2.14.0'
  gem.add_development_dependency 'guard',       '~> 2.6.1'
  gem.add_development_dependency 'guard-rspec', '~> 4.2.9'
  gem.add_development_dependency 'rake',        '~> 10.3.1'
  gem.add_development_dependency 'rb-fsevent',  '~> 0.9.1'
  gem.add_development_dependency 'coveralls'
  gem.add_development_dependency 'appraisal',   '~> 1.0.0'

  if RUBY_PLATFORM == 'java'
    gem.add_development_dependency 'jruby-openssl', '~> 0.7.7'
    gem.add_development_dependency 'activerecord-jdbcsqlite3-adapter'
    gem.add_development_dependency 'activerecord-jdbcpostgresql-adapter'
    gem.add_development_dependency 'activerecord-jdbcmysql-adapter'
  else
    gem.add_development_dependency 'sqlite3'
    gem.add_development_dependency 'pg', '~> 0.17.1'
    gem.add_development_dependency 'mysql2', '~> 0.3.11'
  end
end
