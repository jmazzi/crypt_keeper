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

        self.crypt_keeper_options   = args.extract_options!
        self.crypt_keeper_encryptor = crypt_keeper_options.delete(:encryptor)
        self.crypt_keeper_fields    = args

        ensure_valid_encryptor!

        before_save :enforce_column_types_callback

        crypt_keeper_fields.each do |field|
          serialize field, encryptor_klass.new(crypt_keeper_options)
        end
      end

      private

      # Private: The encryptor class
      def encryptor_klass
        @encryptor_klass ||= "CryptKeeper::Provider::#{crypt_keeper_encryptor.to_s.camelize}".constantize
      end

      # Private: Ensure that the encryptor responds to new
      def ensure_valid_encryptor!
        unless defined?(encryptor_klass) && valid_encryptor?
          raise "You must specify a valid encryptor `crypt_keeper :encryptor => :aes`"
        end
      end

      # Private: Checks if the encryptor response to dump and load
      def valid_encryptor?
        encryptor_klass.instance_methods.include?(:dump) &&
          encryptor_klass.instance_methods.include?(:load)
      end
    end
  end
end

ActiveSupport.on_load :active_record do
  include CryptKeeper::Model
end
