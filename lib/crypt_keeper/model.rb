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

    # Private: A hash of encrypted attributes with their encrypted values
    #
    # Returns a Hash
    def crypt_keeper_dirty_tracking
      @crypt_keeper_dirty_tracking ||= HashWithIndifferentAccess.new
    end

    # Private: Determine if the field's plaintext value changed. It compares
    # it to the original value that came from the DB before decryption
    #
    # Returns boolean
    def plaintext_changed?(field)
      new_record? || self[field] != self.class.decrypt(crypt_keeper_dirty_tracking[field])
    end

    # Private: Encrypt each crypt_keeper_fields
    def encrypt_callback
      crypt_keeper_fields.each do |field|
        if !self[field].nil?
          if plaintext_changed?(field)
            self[field] = self.class.encrypt read_attribute(field)
          else
            self[field] = crypt_keeper_dirty_tracking[field]
            clear_field_changes! field
          end
        end
      end
    end

    # Private: Decrypt each crypt_keeper_fields
    def decrypt_callback
      crypt_keeper_fields.each do |field|
        if !self[field].nil?
          crypt_keeper_dirty_tracking[field] = read_attribute(field)
          self[field] = self.class.decrypt read_attribute(field)
        end

        clear_field_changes! field
      end
    end

    # Private: Run each crypt_keeper_fields through ensure_valid_field!
    def enforce_column_types_callback
      crypt_keeper_fields.each do |field|
        ensure_valid_field! field
      end
    end

    # Private: Removes changes from `#previous_changes` and
    # `#changed_attributes` so the model isn't considered dirty.
    #
    # field - The field to clear
    def clear_field_changes!(field)
      previous_changes.delete(field.to_s)
      changed_attributes.delete(field.to_s)
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
