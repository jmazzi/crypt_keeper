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
          subject.crypt_keeper :storage, :secret
          expect { subject.create! storage: 'asdf' }.to raise_error(ArgumentError, msg)
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
end
