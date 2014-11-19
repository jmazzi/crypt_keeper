require 'active_support/concern'
require 'active_support/core_ext/array/extract_options'

module CryptKeeper
  module Model
    extend ActiveSupport::Concern

    # Public: Ensures that each field exist and is of type text. This prevents
    # encrypted data from being truncated.
    def ensure_valid_field!(field)
      field = "#{field}_encrypted"

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
        class_attribute :crypt_keeper_encoding

        self.crypt_keeper_options   = args.extract_options!
        self.crypt_keeper_encryptor = crypt_keeper_options.delete(:encryptor)
        self.crypt_keeper_encoding  = crypt_keeper_options.delete(:encoding)
        self.crypt_keeper_fields    = args

        ensure_valid_encryptor!

        before_save :enforce_column_types_callback

        crypt_keeper_fields.each do |field|

          # Older ActiveRecord expects strings for arguments
          field = field.to_s

          # ActiveRecord::Dirty methods
          define_method "#{field}_changed?" do
            changed_attributes.include?(field)
          end

          define_method "#{field}_change" do
            attribute_change(field)
          end

          define_method "#{field}_was" do
            attribute_was(field)
          end

          define_method "#{field}_will_change!" do
            attribute_will_change!(field)
          end

          define_method "reset_#{field}!" do
            if attribute_changed?(field)
              send("#{field}=", changed_attributes[field])
              changed_attributes.delete(field)
              send("reset_#{field}_encrypted!")
            end
          end

          # Public: Gets the plaintext for field_encrypted
          define_method "#{field}" do
            self.class.decrypt_value send("#{field}_encrypted")
          end

          # Public: Sets the ciphertext for field_encrypted
          define_method "#{field}=" do |value|
            unless value == self.class.decrypt_value(send("#{field}_encrypted"))
              send("#{field}_will_change!")
              self.send("#{field}_encrypted=", self.class.encrypt_value(value))
            end
          end
        end
      end

      # Public: Decrypt and encode a string
      #
      # value - A string
      #
      # Returns the decrypted string if not empty
      def decrypt_value(value)
        if value.blank?
          value
        else
          force_encoding_on encryptor_klass_instance.decrypt(value)
        end
      end

      # Public: Encrypt and encode a string
      #
      # value - A string
      #
      # Returns the encrypted string if not empty
      def encrypt_value(value)
        value = force_encoding_on(value)

        if value.blank?
          value
        else
          encryptor_klass_instance.encrypt(value.to_s)
        end
      end

      # Public: Searches the field for the given criteria
      #
      # field - The encrypted field to search
      # criteria - A string to search for
      #
      # Returns an ActiveRecord::Collection
      def search_by_plaintext(field, criteria)
        if crypt_keeper_fields.include?(field.to_sym)
          encryptor = encryptor_klass.new(crypt_keeper_options)
          encryptor.search(scoping_strategy, "#{field}_encrypted", criteria)
        else
          raise "#{field} is not a crypt_keeper field"
        end
      end

      # Public: Encrypt a table for the first time.
      def encrypt_table!
        enc       = encryptor_klass.new(crypt_keeper_options)
        tmp_table = Class.new(ActiveRecord::Base).tap { |c| c.table_name = self.table_name }

        transaction do
          tmp_table.find_each do |r|
            crypt_keeper_fields.each do |field|
              r.send("#{field}_encrypted=", enc.encrypt(r["#{field}_encrypted"])) if r["#{field}_encrypted"].present?
            end

            r.save!
          end
        end
      end

      # Public: An instance of encryptor_klass initialized with
      # crypt_keeper_options
      #
      # Returns an instance of the encryptor_klass
      def encryptor_klass_instance
        @encryptor_klass_instance ||= encryptor_klass.new(crypt_keeper_options)
      end

      private

      # Private: Force string encodings if the option is set
      #
      # value - string
      #
      # Returns a string
      def force_encoding_on(value)
        if crypt_keeper_encoding && value.respond_to?(:force_encoding)
          value.force_encoding(crypt_keeper_encoding)
        else
          value
        end
      end

      # Private: The encryptor class
      def encryptor_klass
        @encryptor_klass ||= "CryptKeeper::Provider::#{crypt_keeper_encryptor.to_s.camelize}".constantize
      end

      # Private: Ensure that the encryptor responds to new
      def ensure_valid_encryptor!
        unless defined?(encryptor_klass) && encryptor_klass.respond_to?(:new)
          raise "You must specify a valid encryptor `crypt_keeper :encryptor => :aes`"
        end
      end

      # Private: Determines the scoping method
      #
      # Returns an ActiveRecord::Relation
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
