require 'active_support/concern'
require 'active_support/core_ext/array/extract_options'

module CryptKeeper
  module Model
    extend ActiveSupport::Concern

    def before_save_encrypt
      crypt_keeper_fields.each do |field|
        self[field] = self.class.encrypt read_attribute(field)
      end
    end

    def after_save_decrypt
      crypt_keeper_fields.each do |field|
        self[field] = self.class.decrypt read_attribute(field)
      end
    end

    module ClassMethods
      def crypt_keeper(*fields)
        class_attribute :crypt_keeper_options
        class_attribute :crypt_keeper_fields
        class_attribute :crypt_keeper_encryptor

        self.crypt_keeper_options   = fields.extract_options!
        self.crypt_keeper_encryptor = crypt_keeper_options.delete(:encryptor)
        self.crypt_keeper_fields    = fields

        ensure_valid_encryptor!
        define_crypt_keeper_callbacks
      end

      def encrypt(value)
        encryptor.encrypt value
      end

      def decrypt(value)
        encryptor.decrypt value
      end

      private

      def encryptor
        crypt_keeper_encryptor.new(crypt_keeper_options)
      end

      def ensure_valid_encryptor!
        unless crypt_keeper_encryptor.respond_to?(:new)
          raise "You must specify an encryption class `crypt_keeper encryptor: EncryptionClass`"
        end
      end

      def define_crypt_keeper_callbacks
        after_save :after_save_decrypt
        after_find :after_save_decrypt
        before_save :before_save_encrypt

        crypt_keeper_fields.each do |field|
          ensure_field_is_encryptable! field
        end
      end

      def ensure_field_is_encryptable!(field)
        unless columns_hash["#{field}"].type == :text
          raise ArgumentError, ":#{field} must be of type 'text' to be used for encryption"
        end
      end
    end
  end
end
