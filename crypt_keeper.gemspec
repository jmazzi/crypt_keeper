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

  gem.add_runtime_dependency 'activerecord',           '>= 3.0'
  gem.add_runtime_dependency 'activesupport',          '>= 3.0'
  gem.add_runtime_dependency 'crypt_keeper_providers', '~> 0.1.0'
  gem.add_runtime_dependency 'appraisal',              '~> 0.4.1'

  gem.add_development_dependency 'rspec',       '~> 2.10.0'
  gem.add_development_dependency 'guard',       '~> 1.2.0'
  gem.add_development_dependency 'guard-rspec', '~> 1.1.0'
  gem.add_development_dependency 'rake',        '~> 0.9.2.2'

  if RUBY_PLATFORM == 'java'
    gem.add_development_dependency 'jruby-openssl', '~> 0.7.7'
    gem.add_development_dependency 'activerecord-jdbcsqlite3-adapter'
  else
    gem.add_development_dependency 'sqlite3'
  end
end
