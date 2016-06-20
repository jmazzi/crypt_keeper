require 'active_support/concern'
require 'active_support/core_ext/array/extract_options'

module CryptKeeper
  module Model
    extend ActiveSupport::Concern

    module ClassMethods
      # Public: Setup fields for encryption
      #
      #   args - An array of fields to encrypt. The last argument should be
      #   a hash of options. Note, an :encryptor is required. This should be
      #   a class that takes a hash for initialize and provides an encrypt
      #   and decrypt method.
      #
      # Example
      #
      #   class MyModel < ActiveRecord::Base
      #     crypt_keeper :field, :other_field, :encryptor => :aes, :key => 'super_good_password'
      #   end
      #
      def crypt_keeper(*args)
        class_attribute :crypt_keeper_fields
        class_attribute :crypt_keeper_encryptor
        class_attribute :crypt_keeper_encryptor_instance
        class_attribute :crypt_keeper_options
        class_attribute :crypt_keeper_encoding

        self.crypt_keeper_options            = args.extract_options!
        self.crypt_keeper_encryptor          = crypt_keeper_options.delete(:encryptor)
        self.crypt_keeper_encoding           = crypt_keeper_options.delete(:encoding)
        self.crypt_keeper_fields             = args
        self.crypt_keeper_encryptor_instance = build_encryptor!

        before_save CryptKeeper::Callbacks
        after_save CryptKeeper::Callbacks
        after_find CryptKeeper::Callbacks
      end

      def search_by_plaintext(field, criteria)
        if crypt_keeper_fields.include?(field.to_sym)
          crypt_keeper_encryptor_instance.search(scoping_strategy, field.to_s, criteria)
        else
          raise "#{field} is not a crypt_keeper field"
        end
      end

      # Public: Encrypt a table for the first time.
      def encrypt_table!
        enc       = crypt_keeper_encryptor_instance
        tmp_table = Class.new(ActiveRecord::Base).tap { |c| c.table_name = self.table_name }

        transaction do
          tmp_table.find_each do |r|
            crypt_keeper_fields.each do |field|
              r.send("#{field}=", enc.encrypt(r[field])) if r[field].present?
            end

            r.save!
          end
        end
      end

      # Public: Decrypt a table (reverse of encrypt_table!)
      def decrypt_table!
        enc       = crypt_keeper_encryptor_instance
        tmp_table = Class.new(ActiveRecord::Base).tap { |c| c.table_name = self.table_name }

        transaction do
          tmp_table.find_each do |r|
            crypt_keeper_fields.each do |field|
              r.send("#{field}=", enc.decrypt(r[field])) if r[field].present?
            end

            r.save!
          end
        end
      end

      private

      # Private: The encryptor class
      def encryptor_klass
        @encryptor_klass ||= "CryptKeeper::Provider::#{crypt_keeper_encryptor.to_s.camelize}".constantize
      end

      # Private: Ensure that the encryptor responds to new
      def build_encryptor!
        unless defined?(encryptor_klass) && encryptor_klass.respond_to?(:new)
          raise "You must specify a valid encryptor `crypt_keeper :encryptor => :aes`"
        end

        encryptor_klass.new(crypt_keeper_options)
      end

      def scoping_strategy
        if ::ActiveRecord.respond_to?(:version) && ::ActiveRecord.version.segments[0] == 4
          all
        else
          scoped
        end
      end
    end
  end
end

ActiveSupport.on_load :active_record do
  include CryptKeeper::Model
end
