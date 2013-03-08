require 'spec_helper'

module CryptKeeper
  describe Model do
    use_sqlite

    subject { SensitiveData }

    describe "#crypt_keeper" do
      after(:each) do
        subject.instance_variable_set(:@encryptor_klass, nil)
        subject.instance_variable_set(:@encryptor, nil)
      end

      context "Fields" do
        it "enables encryption for the given fields" do
          subject.crypt_keeper :storage, :secret, encryptor: :fake_encryptor
          subject.crypt_keeper_fields.should == [:storage, :secret]
        end

        it "raises an exception for missing field" do
          msg = "Column :none does not exist"
          subject.crypt_keeper :none, encryptor: :fake_encryptor
          expect { subject.new.save }.to raise_error(ArgumentError, msg)
        end

        it "raises an exception for non text fields" do
          msg = "Column :name must be of type 'text' to be used for encryption"
          subject.crypt_keeper :name, encryptor: :fake_encryptor
          expect { subject.new.save }.to raise_error(ArgumentError, msg)
        end
      end

      context "Options" do
        it "stores options in crypt_keeper_options" do
          subject.crypt_keeper :storage, :secret, key1: 1, key2: 2, encryptor: :fake_encryptor
          subject.crypt_keeper_options.should == { key1: 1, key2: 2  }
        end

        it "accepts the class name as a string" do
          subject.crypt_keeper :storage, :secret, key1: 1, key2: 2, encryptor: "FakeEncryptor"
          subject.send(:encryptor_klass).should == CryptKeeper::Provider::FakeEncryptor
        end

        it "raises an error on missing encryptor" do
          msg = "You must specify an encryptor"
          expect { subject.crypt_keeper :storage, :secret }.to raise_error(ArgumentError, msg)
        end

        it "should set columns for select" do
          subject.crypt_keeper :storage, :secret, encryptor: "FakeEncryptor"
          subject.crypt_keeper_columns_for_select.should == [
            "sensitive_data.id",
            "sensitive_data.name",
            "sensitive_data.storage",
            "sensitive_data.secret"
          ]
        end
      end
    end

    context "Scopes" do
      before do
        SensitiveData.crypt_keeper :storage, passphrase: 'tool', encryptor: :encryptor, type_casts: {storage: :integer}
      end

      describe "#decrypted" do
        let(:record) { SensitiveData.create! storage: "123" }

        it "should select all columns with decrypted values" do
          data = SensitiveData.decrypted.find(record)
          data.attributes.keys.should == ["id", "name", "storage", "secret"]
        end
      end
    end

    context "Encryption" do
      let(:plain_text) { 'plain_text' }
      let(:cipher_text) { 'tooltxet_nialp' }

      before do
        SensitiveData.crypt_keeper :storage, passphrase: 'tool', encryptor: :encryptor
      end

      subject { SensitiveData.new }

      describe "#encrypt" do
        it "should encrypt the data" do
          subject.storage = plain_text
          subject.stub :decrypt_callback
          subject.save!
          subject.storage.should == cipher_text
        end

        it "should not encrypt nil" do
          subject.storage = nil
          subject.stub :decrypt_callback
          subject.save!
          subject.storage.should be_nil
        end
      end

      describe "#decrypt" do
        it "should decrypt the data" do
          subject.storage = cipher_text
          subject.stub :encrypt_callback
          subject.save!
          subject.storage.should == plain_text
        end

        it "should not decrypt nil" do
          subject.storage = nil
          subject.stub :encrypt_callback
          subject.save!
          subject.storage.should be_nil
        end
      end

      describe "Encrypt & Decrypt" do
        it "should encrypt and decrypt the data" do
          subject.storage = plain_text
          subject.save!
          subject.storage.should == plain_text
        end
      end

      describe "#encryptor" do
        let(:encryptor) do
          Class.new do
            def initialize(options = {})
              options.delete :passphrase
            end
          end
        end

        before do
          SensitiveData.crypt_keeper :storage, passphrase: 'tool', encryptor: encryptor
        end

        it "should dup the options" do
          SensitiveData.send :encryptor
          SensitiveData.crypt_keeper_options.should include(passphrase: 'tool')
        end
      end
    end
  end

  describe Model, "with AES provider" do
    use_mysql(true)

    let(:record) { SensitiveData.create! storage: "100" }

    before do
      SensitiveData.instance_variable_set(:@encryptor_klass, nil)
      SensitiveData.instance_variable_set(:@encryptor, nil)
      SensitiveData.crypt_keeper :storage, encryptor: :aes, key: 'secret'
    end

    describe "#decrypted" do
      it "should select all columns" do
        SensitiveData.decrypted.select_values.should == ["sensitive_data.id", "sensitive_data.name", "sensitive_data.storage", "sensitive_data.secret"]
      end

      it "should return decrypted values for retrieved records" do
        data = SensitiveData.decrypted.find(record)
        data.storage.should == "100"
      end
    end
  end

  describe Model, "with MySQL AES provider" do
    use_mysql(true)

    let(:record) { SensitiveData.create! storage: "100" }

    before do
      SensitiveData.instance_variable_set(:@encryptor_klass, nil)
      SensitiveData.instance_variable_set(:@encryptor, nil)
      SensitiveData.crypt_keeper :storage, encryptor: :mysql_aes, key: 'secret'
    end

    describe "#decrypted" do
      it "should select all columns" do
        SensitiveData.decrypted.select_values.should == ["sensitive_data.id", "sensitive_data.name", "sensitive_data.storage", "sensitive_data.secret"]
      end

      it "should return decrypted values for retrieved records" do
        data = SensitiveData.decrypted.find(record)
        data.storage.should == "100"
      end
    end
  end

  describe Model, "with Postgres PGP provider" do
    use_postgres(true)

    let(:record) { SensitiveData.create! storage: "100" }

    before do
      SensitiveData.instance_variable_set(:@encryptor_klass, nil)
      SensitiveData.instance_variable_set(:@encryptor, nil)
      SensitiveData.crypt_keeper :storage, encryptor: :postgres_pgp, key: 'secret'
    end

    describe "#decrypted" do
      it "should select all columns" do
        SensitiveData.decrypted.select_values.should == ["sensitive_data.id", "sensitive_data.name", "pgp_sym_decrypt(sensitive_data.storage::bytea, 'secret') AS \"sensitive_data.storage\"", "sensitive_data.secret"]
      end

      it "should return modified attributes" do
        data = SensitiveData.decrypted.find(record)
        data.attributes.keys.should == ["id", "name", "sensitive_data.storage", "secret"]
      end

      it "should return decrypted values for retrieved records" do
        data = SensitiveData.decrypted.find(record)
        data.storage.should == "100"
      end
    end
  end
end
