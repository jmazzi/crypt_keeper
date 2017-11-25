
v1.1.1 / 2017-06-22
===================

  * Merge pull request #145 from jmazzi/bugfix/decrypt-plaintext
  * Use ActiveRecord::Base.logger.silence to silence when using CryptKeeper.silence_logs?
  * Refactor log filter to include pgp_key_id
  * Checks for the specific exception
  * Refactors encrypted?
  * Fixes serializer issue which calls decrypt with the plaintext value

v1.1.0 / 2017-05-25
===================

  * Releasing 1.1.0
  * Merge pull request #144 from mchaisse/rails_5_1_support
  * Add support for Rails 5.1.x

v1.0.1 / 2017-05-10
===================

  * Merge pull request #142 from jmazzi/bugfix/invalid-statement
  * Filters sql from ActiveRecord::StatementInvalid

v1.0.0 / 2017-05-10
===================

  * Merge pull request #139 from mchaisse/add_binary_as_valid_type
  * Add `binary` as a valid column type

v1.0.0.beta1 / 2017-04-19
=========================

  * Merge pull request #138 from jmazzi/refactor/extend
  * Refactor to check if it respond_to load/dump
  * Raises if Provider does not inherit the base behavior
  * Refactors Provider setup to not extend on instance
  * Merge pull request #137 from campbecf/quote_column_name
  * Quote column name to prevent reserved word issues
  * Merge pull request #130 from jmazzi/refactor/rspec-filenames
  * Avoid `module` in specs
  * Move spec files under spec/crypt_keeper directory
  * Merge pull request #129 from jmazzi/refactor/deprecated-encryptors
  * Remove deprecated encryptors
  * Merge pull request #128 from jmazzi/refactor/rspec3
  * Convert specs to RSpec 3
  * Merge pull request #127 from jmazzi/refactor/alias-method-chain
  * Prefer Module#prepend over alias_method_chain
  * Merge pull request #125 from jmazzi/feature/rails-5-support
  * Support ActiveRecord 4.2 and 5.0 only
  * Merge pull request #124 from jmazzi/refactor/appraisal
  * Update appraisal, tweak rake usage

v0.22.0 / 2016-09-01
====================

  * Merge pull request #121 from jmazzi/feature/silence-logs
  * Allow silencing logging completely

v0.21.0 / 2016-06-21
====================

  * Merge pull request #117 from scottjbarr/fix_sti
  * Merge pull request #118 from jmazzi/pr/116-josh
  * Update test gems
  * Fix encrypt_table for STI
  * Cleanup: Out goes unsupported rails and ruby versions
  * Merge pull request #112 from jmazzi/feature/stub-encryption
  * Add encryption stubbing
  * Merge pull request #113 from jmazzi/upgrade/gemfiles
  * Update gemfiles

v0.20.0 / 2015-04-16
====================

  * Merge pull request #87 from spreemo/add-decrypt-table
  * update crypt_keeper version in multiple gemfile.lock used by travis ci
  * Merge branch 'add-decrypt-table' of github.com:spreemo/crypt_keeper into add-decrypt-table
  * add decrypt table (the reverse of encrypt table)
  * Merge remote-tracking branch 'upstream/master'
  * Rails 4.2 support
  * Added Rails 4.2 support
  * add decrypt table (the reverse of encrypt table)

v0.19.0 / 2015-02-02
====================

  * Block ActiveRecord releases greater than 4.2
  * Fix AR#find depcreation
  * Merge pull request #94 from Ch4s3/support_rails_4_2
  * update to 4.2
  * Merge pull request #95 from saulcosta18/patch-1
  * Fixed typo in list of encryptors
  * Merge pull request #90 from joshk/patch-1
  * Use the new build env on Travis
  * Update gemfiles

v0.18.4 / 2014-10-20
====================

  * Merge pull request #85 from jmazzi/bugfix/reencrypt-blank-fields
  * Merge pull request #83 from jmazzi/bugfix/sti-models
  * Fix reencrypting blank fields
  * Disable STI when reencrypting via CLI

v0.18.3 / 2014-10-20
====================

  * Merge pull request #84 from jmazzi/bugfix/missing_attribute
  * Update gemfiles
  * Ensure attributes are present before forcing an encoding

v0.18.2 / 2014-08-29
====================

  * Merge pull request #80 from jmazzi/bugfix/log_subscriber_encoding
  * Fix UTF-8 issue with log scrubbing
  * Updating deps
  * Add missing mysql aes tests

v0.18.1 / 2014-06-13
====================

  * Merge pull request #77 from jmazzi/bugfix/force_strings
  * Force values to be a string before encrypting
  * Remove encoding and explicitly call storage
  * Merge pull request #75 from jmazzi/refactor/spec_cleanup
  * Use create_model
  * Refactoring for anonymous model
  * Merge pull request #74 from jmazzi/gem_updates
  * Updating deps

v0.18.0 / 2014-05-09
====================

  * Update deps
  * Merge pull request #72 from jmazzi/feature/encrypt_table
  * Add encrypt_table
  * Add encoding instructions to the readme

v0.17.0 / 2014-05-01
====================

  * Update version
  * Merge pull request #69 from jmazzi/feature/encoding_fixes
  * Add the ability to force an encoding on the plaintext
  * Add fury badge

v0.16.1 / 2014-04-25
====================

  * Bump to update description
  * Update README.md

v0.16.0 / 2014-04-25
====================

  * Merge branch 'master' of github.com:jmazzi/crypt_keeper
  * Updating the README
  * Update README.md
  * Update README.md

v0.16.0.pre / 2014-04-21
========================

  * Add query logging
  * Run one update query for each record
  * Merge pull request #67 from jmazzi/refactor/deprecate_aes
  * Deprecate old AES implementations Add Migration script Update ruby and rails versions being tested
  * Update README
  * Merge pull request #60 from jmazzi/feature/pgp_keys
  * Adding public key encryption for postgres
  * Remove old code
  * Version bump
  * Merge pull request #58 from jmazzi/feature/enhanced_aes
  * Note: This is a breaking change which will require re-encrypting all data for anyone using the AES and MySQL AES providers.

v0.15.0.pre / 2013-10-18
========================

  * Merge pull request #57 from jmazzi/feature/nil_and_empty
  * Move empty/nil checking to the model
  * Update README.md
  * Update README.md
  * Merge pull request #53 from jmazzi/feature/searching
  * Add search interface

v0.14.0.pre / 2013-08-26
========================

  * Pre-release
  * Merge pull request #45 from jmazzi/feature/serializer
  * Remove encryption and decryption callbacks, use serializers instead
  * Merge pull request #49 from jmazzi/license
  * Add license to gemspec

v0.13.1 / 2013-06-25
====================

  * Merge pull request #47 from jmazzi/bugfix/appraisal
  * Move appraisal to a development dep

v0.13.0 / 2013-06-03
====================

  * Bump to v0.13.0
  * Merge pull request #43 from fabiokr/options
  * Allows to set options on the postgres_pgp adapter
  * Merge pull request #44 from fabiokr/fix_log_specs
  * Fix log subscribers specs that were using the wrong input

v0.12.0 / 2013-05-30
====================

  * Merge pull request #41 from jmazzi/bugfix/selects
  * Revert escape_and_execute_sql helper
  * Update README.md

v0.11.0 / 2013-05-28
====================

  * Merge pull request #38 from jmazzi/refactor/select_one
  * Use select_one
  * Merge pull request #37 from jmazzi/feature/rails_4
  * Adding rails 4 support
  * Merge pull request #36 from jmazzi/feature/coveralls
  * Wear coveralls

v0.10.0.pre / 2013-04-15
========================

  * Merge pull request #35 from MerchantsBonding/feature-handle-nil-and-empty-string-cleanly
  * Handle nil and empty-string cases in the AES encryption provider
  * Merge pull request #33 from jmazzi/feature/dirty_tracking
  * Merge pull request #27 from rwc9u/iv_randomness

v0.9.0.pre / 2013-03-19
=======================

  * Mark as pre-release
  * Refactor specs, fix spacing
  * Clear dirty attrs on encrypt too
  * Add dirty tracking
  * Changed encryption to user the OpenSSL random_iv instead of rand.to_s because sometimes that is not long enough.

v0.8.0 / 2012-12-24
===================

  * Merge pull request #23 from jmazzi/gemupdates
  * Merge pull request #22 from jmazzi/refactor/cleanup_specs
  * Gem updates
  * Ignore bin
  * Spec cleanups
  * Merge pull request #20 from jmazzi/refactor/log_subscribers
  * Merge pull request #21 from jmazzi/bugfix/missing_encryptor
  * Provide a clear error when you forgot to specify an encryptor
  * Load LogSubscribers on demand.

v0.7.0 / 2012-12-07
===================

  * Merge pull request #17 from jmazzi/refactor/enforce_column_type
  * Update appraisal
  * Move column checking to the instance level

v0.6.1 / 2012-12-07
===================

  * Merge pull request #18 from fabiokr/feature/check_field_presence
  * Checks if field exist

v0.6.0 / 2012-10-11
===================

  * Merge pull request #15 from jmazzi/bugfix/force_strings
  * PostgreSQL expects strings when using pgp_sym_encrypt/decrypt functions.
  * Merge pull request #14 from jmazzi/refactor/helper
  * Move this into the model
  * Move common SQL methods to a helper
  * Merge pull request #10 from jmazzi/bugfix/mysql_aes_base64
  * Use Base64.encode/decode after/befor encrypting
  * Merge pull request #9 from jmazzi/bugfix/mysql_aes
  * Update appraisal
  * Fix specs that were not running
  * Update README.md

v0.5.0 / 2012-09-03
===================

  * Update README.md
  * Merge pull request #7 from jmazzi/refactor/merge_providers
  * Do not try to encrypt or decrypt nil
  * Update gemfiles
  * Jruby 1.9 mode
  * Add jruby, allow failure
  * Update README
  * Adding providers and subscribers

v0.4.2 / 2012-08-30
===================

  * Update crypt_keeper_providers
  * Update README.md

v0.4.1 / 2012-08-30
===================

  * Bump appraisal
  * Merge pull request #6 from jmazzi/feature/update_deps
  * Update crypt_keeper_providers
  * Merge pull request #5 from jmazzi/feature/gem_updates
  * Updating dependencies

v0.4.0 / 2012-08-01
===================

  * Updating crypt_keeper_providers
  * Merge pull request #2 from itspriddle/readme-update
  * Update readme
  * Update README.md

v0.3.0 / 2012-07-30
===================

  * Updating version
  * Update README
  * Update guard syntax
  * Removing jruby testing. It's generating some odd errors on travis-ci :/
  * Add log subscriber note
  * Update README
  * Adding Requirements
  * Adding appraisal
  * Add a note about `update_column`
  * Merge pull request #1 from drichert/update/docs
  * Add homepage
  * Clear @encryptor/@encryptor_klass in after hook
  * Update README/spec; encryptor option can be a string
  * Fix typo

v0.2.0 / 2012-07-27
===================

  * Update README

v0.1.0 / 2012-07-27
===================

  * Cache the encryptor
  * Update examples
  * Update example
  * Update docs
  * Refactor how encryptors are set
  * Rename this methods
  * Add travis image
  * Adding img :)
  * Build!
  * Update deps

v0.0.4 / 2012-07-26
===================

  * Bump dep
  * Only require sqlite3 for MRI
  * Gotta add Travis! cc @joshk, @svenfuchs :-D
  * Update README

v0.0.3 / 2012-07-26
===================

  * Dupe options to prevent them from being modified

v0.0.2 / 2012-07-26
===================

  * Bump version
  * Update README Require the providers

v0.0.1 / 2012-07-26
===================

  * Move Usage to the top
  * Update README
  * Adding description
  * Update docs
  * Add crypt_keeper_providers
  * Add jruby support
  * Adding rspec as the default rake task
  * Add jruby-openssl
  * Adding docs, moving some methods to private
  * Rename
  * Add rake
  * Remove the encryptor, not needed
  * Importing

