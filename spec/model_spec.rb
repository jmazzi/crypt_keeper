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

      context "Type casting" do
        it "should return given value when typecasting an attribute without type cast" do
          subject.type_cast("value", :foo).should == "value"
        end

        it "should return given string when casting to string" do
          subject.type_cast("value", :string).should == "value"
        end

        it "should return given string when casting to text" do
          subject.type_cast("value", :text).should == "value"
        end

        it "should allow casting integer value to Fixnum" do
          subject.type_cast("123.45", :integer).should == 123
        end

        it "should allow casting float value to Float" do
          subject.type_cast("123.45", :float).should == 123.45
        end

        it "should allow casting decimal value to BigDecimal" do
          subject.type_cast("123.45", :decimal).should == BigDecimal.new("123.45")
        end

        it "should allow casting datetime value to Time" do
          subject.type_cast("2000-01-01 12:00:00", :datetime).should be_kind_of(Time)
        end

        it "should allow casting timestamp value to Time" do
          subject.type_cast("2000-01-01 12:00:00", :timestamp).should be_kind_of(Time)
        end

        it "should allow casting time attribute to dummy time" do
          subject.type_cast("12:04:53", :time).should == Time.local(2000, 1, 1, 12, 4, 53)
        end

        it "should allow casting date attribute to Date" do
          subject.type_cast("2000-01-01", :date).should == Date.new(2000, 1, 1)
        end

        it "should cast boolean attribute from boolean" do
          subject.type_cast(nil, :boolean).should be_nil
          subject.type_cast(true, :boolean).should be_true
          subject.type_cast(false, :boolean).should be_false
        end

        it "should cast booleans from string" do
          subject.type_cast("", :boolean).should be_nil
          subject.type_cast("0", :boolean).should be_false
          subject.type_cast("1", :boolean).should be_true
          subject.type_cast("f", :boolean).should be_false
          subject.type_cast("t", :boolean).should be_true
        end
      end

      context "Fields" do
        it "enables encryption for the given fields" do
          subject.crypt_keeper :storage, :secret, encryptor: :fake_encryptor
          subject.crypt_keeper_fields.should == {storage: :text, secret: :text}
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
          subject.crypt_keeper :storage, :secret
          expect { subject.create! storage: 'asdf' }.to raise_error(ArgumentError, msg)
        end

        it "should defaults type casts of fields to :text" do
          subject.crypt_keeper :storage, :secret, encryptor: "FakeEncryptor"
          subject.crypt_keeper_fields.should == {storage: :text, secret: :text}
        end

        it "should set type casts if provided" do
          subject.crypt_keeper :secret, encryptor: "FakeEncryptor", fields: {storage: :date}
          subject.crypt_keeper_fields.should == {
            storage: :date,
            secret: :text
          }
        end
        
        it "should set type cast from fields hash" do
          subject.crypt_keeper :secret, encryptor: "FakeEncryptor", fields: {storage: :date, secret: :integer}
          subject.crypt_keeper_fields.should == {
            storage: :date,
            secret:  :integer
          }
        end
      end
    end

    context "Encryption" do
      let(:plain_text) { '123456789' }
      let(:cipher_text) { 'tool987654321' }

      before do
        SensitiveData.crypt_keeper :storage, passphrase: 'tool', encryptor: :encryptor, fields: {storage: :integer}
      end

      subject { SensitiveData.new }

      describe "#encrypt" do
        it "should encrypt the data" do
          subject.storage = plain_text
          subject.stub :decrypt_callback
          subject.save!
          subject.storage.should == cipher_text
        end

        it "should encrypt the data that is not string" do
          subject.storage = 123456789
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
        it "should decrypt and type cast the data" do
          subject.storage = cipher_text
          subject.stub :encrypt_callback
          subject.save!
          subject.storage.should == 123456789
        end

        it "should not decrypt nil" do
          subject.storage = nil
          subject.stub :encrypt_callback
          subject.save!
          subject.storage.should be_nil
        end
      end

      describe "Encrypt & Decrypt" do
        it "should encrypt and decrypt the data performing type cast" do
          subject.storage = plain_text
          subject.save!
          subject.storage.should == 123456789
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
end
