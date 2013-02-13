# -*- encoding: utf-8 -*-
require File.expand_path('../lib/crypt_keeper/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Justin Mazzi"]
  gem.email         = ["jmazzi@gmail.com"]
  gem.description   = %q{Transparent encryption for ActiveRecord that isn't over-engineered}
  gem.summary       = gem.description
  gem.homepage      = "http://jmazzi.github.com/crypt_keeper/"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "crypt_keeper"
  gem.require_paths = ["lib"]
  gem.version       = CryptKeeper::VERSION

  gem.add_runtime_dependency 'activesupport',          '>= 3.0'
  gem.add_runtime_dependency 'appraisal',              '~> 0.5.1'

  gem.add_development_dependency 'activerecord', '>= 3.0'
  gem.add_development_dependency 'mongoid',     '~> 3.1.0'
  gem.add_development_dependency 'rspec',       '~> 2.12.0'
  gem.add_development_dependency 'guard',       '~> 1.6.0'
  gem.add_development_dependency 'guard-rspec', '~> 2.3.0'
  gem.add_development_dependency 'rake',        '~> 10.0.3'
  gem.add_development_dependency 'rb-fsevent',  '~> 0.9.1'

  if RUBY_PLATFORM == 'java'
    gem.add_development_dependency 'jruby-openssl', '~> 0.7.7'
    gem.add_development_dependency 'activerecord-jdbcsqlite3-adapter'
    gem.add_development_dependency 'activerecord-jdbcpostgresql-adapter'
    gem.add_development_dependency 'activerecord-jdbcmysql-adapter'
  else
    gem.add_development_dependency 'sqlite3'
    gem.add_development_dependency 'pg', '~> 0.14.0'
    gem.add_development_dependency 'mysql2', '~> 0.3.11'
  end
end
