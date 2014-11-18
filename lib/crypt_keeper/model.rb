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

    def force_string_encodings(value)
      if self.class.crypt_keeper_encoding && value.respond_to?(:force_encoding)
        value.force_encoding(self.class.crypt_keeper_encoding)
      else
        value
      end
    end

    # Private: Run each crypt_keeper_fields through ensure_valid_field!
    def enforce_column_types_callback
      crypt_keeper_fields.each do |field|
        ensure_valid_field! field
      end
    end

    def encrypt_fields
      crypt_keeper_fields.each do |field|
        value = read_attribute(field)
        value = force_string_encodings(value)

        if value.present?
          self.send("#{field}=", self.class.encryptor_klass_instance.encrypt(value.to_s))
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
        before_save :encrypt_fields

        crypt_keeper_fields.each do |field|
          define_method "#{field}" do
            value = read_attribute(field)

            if value.present?
              force_string_encodings self.class.encryptor_klass_instance.decrypt(value).to_s
            else
              value
            end
          end
        end
      end

      def search_by_plaintext(field, criteria)
        if crypt_keeper_fields.include?(field.to_sym)
          encryptor = encryptor_klass.new(crypt_keeper_options)
          encryptor.search(scoping_strategy, field.to_s, criteria)
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
              r.send("#{field}=", enc.encrypt(r[field])) if r[field].present?
            end

            r.save!
          end
        end
      end

      # Public: The instance of the encryptor_klass with options
      #
      # Returns an instance encryptor_klass
      def encryptor_klass_instance
        @encryptor_klass_instance ||= encryptor_klass.new(crypt_keeper_options)
      end

      private

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
