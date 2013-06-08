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
        it "accepts the class name as a string" do
          subject.crypt_keeper :storage, :secret, key1: 1, key2: 2, encryptor: "FakeEncryptor"
          subject.send(:encryptor_klass).should == CryptKeeper::Provider::FakeEncryptor
        end

        it "raises an error on missing encryptor" do
          expect { subject.crypt_keeper :storage, :secret }.
            to raise_error(RuntimeError, /You must specify a valid encryptor/)
        end
      end
    end

    context "Encryption and Decryption" do
      let(:plain_text) { 'plain_text' }
      let(:cipher_text) { 'tooltxet_nialp' }
      let(:encryptor) { CryptKeeper::Provider::Encryptor }

      before do
        SensitiveData.crypt_keeper :storage, passphrase: 'tool', encryptor: :encryptor
      end

      it "encrypts the data" do
        CryptKeeper::Provider::Encryptor.any_instance.should_receive(:dump).with('testing')
        SensitiveData.create!(storage: 'testing')
      end

      it "decrypts the data" do
        record = SensitiveData.create!(storage: 'testing')
        CryptKeeper::Provider::Encryptor.any_instance.should_receive(:load).at_least(1).times.with('toolgnitset')
        SensitiveData.find(record).storage
      end

      it "returns the plaintext on decrypt" do
        record = SensitiveData.create!(storage: 'testing')
        SensitiveData.find(record).storage.should == 'testing'
      end
    end
  end
end
