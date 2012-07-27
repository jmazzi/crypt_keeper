require 'spec_helper'

module CryptKeeper
  describe Model do
    subject { SensitiveData }
    describe "#crypt_keeper" do
      context "Fields" do
        it "should set the fields" do
          subject.crypt_keeper :storage, :secret, encryptor: :fake_encryptor
          subject.crypt_keeper_fields.should == [:storage, :secret]
        end

        it "should raise an exception with wrong field type" do
          msg = ":name must be of type 'text' to be used for encryption"
          expect { subject.crypt_keeper :name, encryptor: :fake_encryptor }.to raise_error(ArgumentError, msg)
        end
      end

      context "Options" do
        it "should set the options" do
          subject.crypt_keeper :storage, :secret, key1: 1, key2: 2, encryptor: :fake_encryptor
          subject.crypt_keeper_options.should == { key1: 1, key2: 2  }
        end

        it "should accept class name (as string) for encryptor option" do
          subject.crypt_keeper :storage, :secret, key1: 1, key2: 2, encryptor: "FakeEncryptor"
          subject.send(:encryptor_klass).should == CryptKeeperProviders::FakeEncryptor

          subject.instance_variable_set(:@encryptor_klass, nil)
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
      end

      describe "#decrypt" do
        it "should decrypt the data" do
          subject.storage = cipher_text
          subject.stub :encrypt_callback
          subject.save!
          subject.storage.should == plain_text
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
