require 'active_support/concern'
require 'active_support/core_ext/array/extract_options'

module CryptKeeper
  module Model
    extend ActiveSupport::Concern

    # Public: Ensures that each field exist and is of type text. This prevents
    # encrypted data from being truncated.
    def ensure_valid_field!(field)
      if self.class.columns_hash["#{field}"].nil?
        raise ArgumentError, "Column :#{field} does not exist"
      elsif self.class.columns_hash["#{field}"].type != :text
        raise ArgumentError, "Column :#{field} must be of type 'text' to be used for encryption"
      end
    end

    private

    # Private: Run each crypt_keeper_fields through ensure_valid_field!
    def enforce_column_types_callback
      crypt_keeper_fields.each do |field|
        ensure_valid_field! field
      end
    end

    # Private: Force string encodings if the option is set
    def force_encodings_on_fields
      crypt_keeper_fields.each do |field|
        if attributes.has_key?(field.to_s) && send(field).respond_to?(:force_encoding)
          send(field).force_encoding(crypt_keeper_encoding)
        end
      end
    end

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
        class_attribute :crypt_keeper_options
        class_attribute :crypt_keeper_encoding

        self.crypt_keeper_options   = args.extract_options!
        self.crypt_keeper_encryptor = crypt_keeper_options.delete(:encryptor)
        self.crypt_keeper_encoding  = crypt_keeper_options.delete(:encoding)
        self.crypt_keeper_fields    = args

        ensure_valid_encryptor!

        before_save :enforce_column_types_callback

        if self.crypt_keeper_encoding
          after_find :force_encodings_on_fields
          before_save :force_encodings_on_fields
        end

        crypt_keeper_fields.each do |field|
          serialize field, encryptor
        end
      end

      def search_by_plaintext(field, criteria)
        if crypt_keeper_fields.include?(field.to_sym)
          encryptor.search(all, field.to_s, criteria)
        else
          raise ArgumentError, "#{field} is not a crypt_keeper field"
        end
      end

      # Public: Encrypt a table for the first time.
      def encrypt_table!
        tmp_table = Class.new(ActiveRecord::Base).tap do |c|
          c.table_name = self.table_name
          c.inheritance_column = :type_disabled
        end

        transaction do
          tmp_table.find_each do |r|
            crypt_keeper_fields.each do |field|
              r.send("#{field}=", encryptor.encrypt(r[field])) if r[field].present?
            end

            r.save!
          end
        end
      end

      # Public: Decrypt a table (reverse of encrypt_table!)
      def decrypt_table!
        tmp_table = Class.new(ActiveRecord::Base).tap { |c| c.table_name = self.table_name }

        transaction do
          tmp_table.find_each do |r|
            crypt_keeper_fields.each do |field|
              r.send("#{field}=", encryptor.decrypt(r[field])) if r[field].present?
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

      # Private: The encryptor instance.
      def encryptor
        @encryptor ||= encryptor_klass.new(crypt_keeper_options)
      end

      # Private: Ensure we have a valid encryptor.
      def ensure_valid_encryptor!
        unless defined?(encryptor_klass) && encryptor_klass.respond_to?(:new) &&
          %i(load dump).all? { |m| encryptor.respond_to?(m) }
          raise ArgumentError, "You must specify a valid encryptor that implements " \
            "the `load` and `dump` methods (you can inherit from CryptKeeper::Provider::Base). Example: `crypt_keeper :encryptor => :aes`"
        end
      end
    end
  end
end

ActiveSupport.on_load :active_record do
  include CryptKeeper::Model
end
