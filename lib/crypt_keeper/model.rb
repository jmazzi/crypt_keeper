require 'active_support/concern'
require 'active_support/core_ext/array/extract_options'

module CryptKeeper
  module Model
    extend ActiveSupport::Concern

    def self.included(base)
      CryptKeeper::Persistence.set_persistence(base)
    end

    private

    # Private: Encrypt each crypt_keeper_fields
    def encrypt_callback
      crypt_keeper_fields.each do |field|
        if !self[field].nil?
          self[field] = self.class.encrypt read_attribute(field)
        end
      end
    end

    # Private: Decrypt each crypt_keeper_fields
    def decrypt_callback
      crypt_keeper_fields.each do |field|
        if !self[field].nil?
          self[field] = self.class.decrypt read_attribute(field)
        end
      end
    end

    # Private: Run each crypt_keeper_fields through ensure_valid_field!
    def enforce_column_types_callback
      crypt_keeper_fields.each do |field|
        ensure_valid_field! field
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
        @encryptor ||= if crypt_keeper_encryptor.blank?
                         raise ArgumentError.new('You must specify an encryptor')
                       else
                         encryptor_klass.new(crypt_keeper_options.dup)
                       end
      end

      # Private: The encryptor class
      def encryptor_klass
        @encryptor_klass ||= "CryptKeeper::Provider::#{crypt_keeper_encryptor.to_s.camelize}".constantize
      end

      # Private: Ensure that the encryptor responds to new
      def ensure_valid_encryptor!
        unless defined? encryptor_klass
          raise "You must specify a valid encryptor `crypt_keeper :encryptor => :aes`"
        end
      end

      # Private: Define callbacks for encryption
      def define_crypt_keeper_callbacks
        after_save :decrypt_callback
        after_find :decrypt_callback
        before_save :encrypt_callback
        before_save :enforce_column_types_callback
      end
    end
  end
end

ActiveSupport.on_load :active_record do
  include CryptKeeper::Model
end
