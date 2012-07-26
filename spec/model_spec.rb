require 'spec_helper'

module CryptKeeper
  describe Model do
    subject { SensitiveData }
    let(:encryptor) do
      mock('Encryptor').tap do |m|
        m.stub :new
      end
    end

    describe "#crypt_keeper" do
      context "Fields" do
        it "should set the fields" do
          subject.crypt_keeper :storage, :secret, encryptor: encryptor
          subject.crypt_keeper_fields.should == [:storage, :secret]
        end

        it "should raise an exception with wrong field type" do
          msg = ":name must be of type 'text' to be used for encryption"
          expect { subject.crypt_keeper :name, encryptor: encryptor }.to raise_error(ArgumentError, msg)
        end
      end

      context "Options" do
        it "should set the options" do
          subject.crypt_keeper :storage, :secret, key1: 1, key2: 2, encryptor: encryptor
          subject.crypt_keeper_options.should == { key1: 1, key2: 2  }
        end
      end
    end

    context "Encryption" do
      let(:encryptor) do
        Class.new do
          def initialize(options = {})
            @passphrase = options[:passphrase]
          end

          def encrypt(data)
            @passphrase + data.reverse
          end

          def decrypt(data)
            data.sub(/^#{@passphrase}/, '').reverse
          end
        end
      end

      let(:plain_text) { 'plain_text' }
      let(:cipher_text) { 'tooltxet_nialp' }

      before do
        SensitiveData.crypt_keeper :storage, passphrase: 'tool', encryptor: encryptor
      end

      subject { SensitiveData.new }

      describe "#encrypt" do
        it "should encrypt the data" do
          subject.storage = plain_text
          subject.stub :after_save_decrypt
          subject.save!
          subject.storage.should == cipher_text
        end
      end

      describe "#decrypt" do
        it "should decrypt the data" do
          subject.storage = cipher_text
          subject.stub :before_save_encrypt
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
    end
  end
end
