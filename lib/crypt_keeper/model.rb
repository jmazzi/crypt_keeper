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

    # Private: Encrypt each crypt_keeper_fields
    def encrypt_callback
      crypt_keeper_fields.each do |field, type|
        if !self[field].nil?
          self[field] = self.class.encrypt read_attribute(field)
        end
      end
    end

    # Private: Decrypt each crypt_keeper_fields
    def decrypt_callback
      crypt_keeper_fields.each do |field, type|
        if !self[field].nil?
          self[field] = self.class.type_cast(self.class.decrypt(read_attribute(field)), type)
        end
      end
    end

    # Private: Run each crypt_keeper_fields through ensure_valid_field!
    def enforce_column_types_callback
      crypt_keeper_fields.each do |field, type|
        ensure_valid_field! field
      end
    end

    module ClassMethods
      # Public: Setup fields for encryption
      #
      #   args - An array of fields to encrypt and options hash. The last
      #   argument should be a hash of options. Note, an :encryptor is
      #   required. This should be a class that takes a hash for initialize
      #   and provides an encrypt and decrypt method.
      #   You can also pass fields to encrypt as :fields key in options hash,
      #   with fields as keys and types as values. Values would be type casted
      #   to given types in decrypt callback. The default type (used when
      #   passing field names as array) is :text.
      #   Available types: :string, :text, :integer, :float, :decimal, :datetime,
      #   :timestamp, :time, :date, :binary, :boolean
      #
      # Examples
      #
      #   class MyModel < ActiveRecord::Base
      #     crypt_keeper :field, :other_field, :encryptor => :aes, :key => 'super_good_password'
      #   end
      #
      #  class MyModel < ActiveRecord::Base
      #    crypt_keeper :fields => {:field => :integer, :date_field => :datetime}, :encryptor => :aes, :key => 'super_good_password'
      #  end
      #
      #
      def crypt_keeper(*args)
        class_attribute :crypt_keeper_options
        class_attribute :crypt_keeper_fields
        class_attribute :crypt_keeper_encryptor

        self.crypt_keeper_options    = args.extract_options!
        self.crypt_keeper_encryptor  = crypt_keeper_options.delete(:encryptor)
        self.crypt_keeper_fields     = crypt_keeper_options.delete(:fields) || {}
        args.each{ |arg| self.crypt_keeper_fields[arg] ||= :text }

        ensure_valid_encryptor!
        define_crypt_keeper_callbacks
      end

      # Public: Encrypts a string with the encryptor
      def encrypt(value)
        encryptor.encrypt value.to_s
      end

      # Public: Decrypts a string with the encryptor
      def decrypt(value)
        encryptor.decrypt value
      end

      # Public: Casts value (which is a String) to appropriate instance
      def type_cast(value, type)
        return nil if value.nil?

        klass = ::ActiveRecord::ConnectionAdapters::Column
        case type
          when :string, :text        then value
          when :integer              then klass.respond_to?(:value_to_integer) ? klass.value_to_integer(value) : (value.to_i rescue value ? 1 : 0)
          when :float                then value.to_f
          when :decimal              then klass.value_to_decimal(value)
          when :datetime, :timestamp then klass.string_to_time(value)
          when :time                 then klass.string_to_dummy_time(value)
          when :date                 then klass.respond_to?(:value_to_date) ? klass.value_to_date(value) : klass.string_to_date(value)
          when :binary               then klass.binary_to_string(value)
          when :boolean              then klass.value_to_boolean(value)
          else value
        end
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
