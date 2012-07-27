require 'active_support/concern'
require 'active_support/core_ext/array/extract_options'

module CryptKeeper
  module Model
    extend ActiveSupport::Concern

    private

    # Private: Encrypt each crypt_keeper_fields
    def before_save_encrypt
      crypt_keeper_fields.each do |field|
        self[field] = self.class.encrypt read_attribute(field)
      end
    end

    # Private: Decrypt each crypt_keeper_fields
    def after_save_decrypt
      crypt_keeper_fields.each do |field|
        self[field] = self.class.decrypt read_attribute(field)
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
      #     crypt_keeper :field, :other_field, encryptor: Aes, passphrase: 'super_good_password'
      #   end
      #
      def crypt_keeper(*args)
        class_attribute :crypt_keeper_options
        class_attribute :crypt_keeper_fields
        class_attribute :crypt_keeper_encryptor

        self.crypt_keeper_options   = args.extract_options!
        self.crypt_keeper_encryptor = crypt_keeper_options.delete(:encryptor)
        self.crypt_keeper_fields    = args

        ensure_valid_encryptor!
        define_crypt_keeper_callbacks
      end

      # Public: Encrypts a string with the encryptor
      def encrypt(value)
        encryptor.encrypt value
      end

      # Public: Decrypts a string with the encryptor
      def decrypt(value)
        encryptor.decrypt value
      end

      private

      # Private: An instance of the encryptor class
      def encryptor
        crypt_keeper_encryptor.new(crypt_keeper_options)
      end

      # Private: Ensure that the encryptor responds to new
      def ensure_valid_encryptor!
        unless crypt_keeper_encryptor.respond_to?(:new)
          raise "You must specify an encryption class `crypt_keeper encryptor: EncryptionClass`"
        end
      end

      # Private: Define callbacks for encryption
      def define_crypt_keeper_callbacks
        after_save :after_save_decrypt
        after_find :after_save_decrypt
        before_save :before_save_encrypt

        crypt_keeper_fields.each do |field|
          ensure_field_is_encryptable! field
        end
      end

      # Private: Ensures that each field is of type text. This prevents
      # encrypted data from being truncated
      def ensure_field_is_encryptable!(field)
        unless columns_hash["#{field}"].type == :text
          raise ArgumentError, ":#{field} must be of type 'text' to be used for encryption"
        end
      end
    end
  end
end
