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
        before do
          subject.crypt_keeper :storage, encryptor: :fake_encryptor, type_casts: {
            string_attribute: :string,
            text_attribute: :text,
            integer_attribute: :integer,
            float_attribute: :float,
            decimal_attribute: :decimal,
            datetime_attribute: :datetime,
            timestamp_attribute: :timestamp,
            time_attribute: :time,
            date_attribute: :date,
            binary_attribute: :binary,
            boolean_attribute: :boolean
          }
        end
        it "should return given value when typecasting an attribute without type cast" do
          subject.type_cast(:foo, "value").should == "value"
        end

        it "should return given string when casting to string" do
          subject.type_cast(:string_attribute, "value").should == "value"
        end

        it "should return given string when casting to text" do
          subject.type_cast(:text_attribute, "value").should == "value"
        end

        it "should allow casting integer value to Fixnum" do
          subject.type_cast(:integer_attribute, "123.45").should == 123
        end

        it "should allow casting float value to Float" do
          subject.type_cast(:float_attribute, "123.45").should == 123.45
        end

        it "should allow casting decimal value to BigDecimal" do
          subject.type_cast(:decimal_attribute, "123.45").should == BigDecimal.new("123.45")
        end

        it "should allow casting datetime value to Time" do
          subject.type_cast(:datetime_attribute, "2000-01-01 12:00:00").should be_kind_of(Time)
        end

        it "should allow casting timestamp value to Time" do
          subject.type_cast(:timestamp_attribute, "2000-01-01 12:00:00").should be_kind_of(Time)
        end

        it "should allow casting time attribute to dummy time" do
          subject.type_cast(:time_attribute, "12:04:53").should == Time.local(2000, 1, 1, 12, 4, 53)
        end

        it "should allow casting date attribute to Date" do
          subject.type_cast(:date_attribute, "2000-01-01").should == Date.new(2000, 1, 1)
        end

        it "should cast boolean attribute from boolean" do
          subject.type_cast(:boolean_attribute, nil).should be_nil
          subject.type_cast(:boolean_attribute, true).should be_true
          subject.type_cast(:boolean_attribute, false).should be_false
        end

        it "should cast booleans from string" do
          subject.type_cast(:boolean_attribute, "").should be_nil
          subject.type_cast(:boolean_attribute, "0").should be_false
          subject.type_cast(:boolean_attribute, "1").should be_true
          subject.type_cast(:boolean_attribute, "f").should be_false
          subject.type_cast(:boolean_attribute, "t").should be_true
        end
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
          subject.crypt_keeper :storage, :secret
          expect { subject.create! storage: 'asdf' }.to raise_error(ArgumentError, msg)
        end

        it "should defaults type casts hash to empty hash" do
          subject.crypt_keeper :storage, :secret, encryptor: "FakeEncryptor"
          subject.crypt_keeper_type_casts.should == {}
        end

        it "should set type casts if provided" do
          subject.crypt_keeper :storage, :secret, encryptor: "FakeEncryptor", type_casts: {storage: :date, secret: :integer}
          subject.crypt_keeper_type_casts.should == {
            storage: :date,
            secret: :integer
          }
        end
      end
    end

    context "Encryption" do
      let(:plain_text) { '123456789' }
      let(:cipher_text) { 'tool987654321' }

      before do
        SensitiveData.crypt_keeper :storage, passphrase: 'tool', encryptor: :encryptor, type_casts: {storage: :integer}
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
