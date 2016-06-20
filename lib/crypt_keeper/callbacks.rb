module CryptKeeper
  # This class encapsulates ActiveRecord Callbacks run when a CryptKeeper
  # model is saved or fetched from the database.
  class Callbacks
    # Public: Called when the given record's `after_save` callback fires.
    #
    # record - An ActiveRecord instance
    #
    # Returns true if the callback succeeded.
    def self.after_save(record)
      new(record).after_save!
    end

    # Public: Called when the given record's `after_find` callback fires.
    #
    # record - An ActiveRecord instance
    #
    # Returns true if the callback succeeded.
    def self.after_find(record)
      new(record).after_find!
    end

    # Public: Called when the given record's `before_save` callback fires.
    #
    # record - An ActiveRecord instance
    #
    # Returns true if the callback succeeded.
    def self.before_save(record)
      new(record).before_save!
    end

    # record - An ActiveRecord instance
    def initialize(record)
      @record    = record
      @model     = record.class
      @encryptor = @model.crypt_keeper_encryptor_instance
      @fields    = @model.crypt_keeper_fields.map(&:to_s) & record.attributes.keys
    end

    # Public: Run before the model is saved.
    #
    # * Verify columns are the proper type
    # * Force encoding on column values (if configured)
    # * Encrypts fields
    #
    # Returns true if the callback succeeded.
    def before_save!
      enforce_column_types!
      force_encoding!

      @fields.each do |name|
        if changes[name].present?
          @record.send("#{name}=", encrypt(@record.send(name)))
        end
      end

      true
    end

    # Public: Run after the model is saved.
    #
    # * Decrypts fields (they are already encrypted at this point)
    #
    # force - If true, force decryption on fields without checking for changes
    #
    # Returns true if the callback succeeded.
    def after_save!(force: false)
      @fields.each do |name|
        if force || changes[name].present?
          @record.send("#{name}=", decrypt(@record.send(name)))
        end
      end

      true
    end

    # Public: Run after a model is loaded from the database.
    #
    # * Decrypts fields (they are already encrypted at this point)
    # * Force encoding on column values (if configured)
    # * Resets ActiveRecord::Dirty changes on CryptKeepr columns due to
    #   encryption/decryption/encoding
    #
    # Returns true if the callback succeeded.
    def after_find!
      after_save! force: true
      force_encoding!
      clear_changes!

      true
    end

    private

    # Private: Encrypts the given value. If `CryptKeeper.stub_encryption` is
    # enabled, or the given value is nil or a blank string, no encryption is
    # run.
    #
    # value - The value to encrypt
    #
    # Returns a String or nil.
    def encrypt(value)
      if CryptKeeper.stub_encryption? || value.nil? || value == "".freeze
        value
      else
        @encryptor.encrypt(value.to_s)
      end
    end

    # Private: Decrypts the given value. If `CryptKeeper.stub_encryption` is
    # enabled, or the given value is nil or a blank string, no decryption is
    # run.
    #
    # value - The value to encrypt
    #
    # Returns a String or nil.
    def decrypt(value)
      if CryptKeeper.stub_encryption? || value.nil? || value == "".freeze
        value
      else
        @encryptor.decrypt(value.to_s)
      end
    end

    # Private: Forces encoding on encrypted fields if configured.
    #
    # Returns nothing.
    def force_encoding!
      if encoding = @model.crypt_keeper_encoding
        @fields.each do |field|
          @record.send(field).try(:force_encoding, encoding)
        end
      end
    end

    # Private: Verifies that encrypted fields exist and are of type "text".
    #
    # Raises ArgumentError if any fields are not configured properly.
    #
    # Returns nothing.
    def enforce_column_types!
      @model.crypt_keeper_fields.each do |field|
        if @model.columns_hash[field.to_s].nil?
          raise ArgumentError, "Column :#{field} does not exist"
        elsif @model.columns_hash[field.to_s].type != :text
          raise ArgumentError, "Column :#{field} must be of type 'text' to be used for encryption"
        end
      end
    end

    # Private: ActiveRecord::Dirty changes for the current record. We cache
    # them because serialized attributes run their serializer's load/dump
    # methods every time `#changes` is run.
    #
    # Returns a Hash.
    def changes
      @changes ||= @record.changes
    end

    # Private: Clears ActiveRecord::Dirty changes for CryptKeeper fields.
    #
    # Returns nothing.
    def clear_changes!
      if @record.respond_to?(:clear_attribute_changes, true)
        # ActiveRecord >= 4.2
        @record.send(:clear_attribute_changes, @fields)
      else
        # ActiveRecord < 4.2
        @fields.each do |field|
          @record.send(:previous_changes).delete(field)
          @record.send(:changed_attributes).delete(field)
        end
      end
    end
  end
end
