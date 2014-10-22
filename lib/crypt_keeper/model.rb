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
          serialize field, encryptor_klass.new(crypt_keeper_options).
            extend(::CryptKeeper::Helper::Serializer)
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

      def without_encrypted
        fields = column_names.map(&:to_sym) - crypt_keeper_fields

        select(fields).tap do |s|
          s.define_singleton_method(:count) do |column = primary_key, opts = {}|
            super(column, opts)
          end
        end
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
