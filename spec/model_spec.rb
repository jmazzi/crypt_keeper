# encoding: utf-8

require 'spec_helper'

module CryptKeeper
  describe Model do
    use_postgres

    subject { create_model }

    describe "#crypt_keeper" do
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

      subject { create_encrypted_model :storage, passphrase: 'tool', encryptor: :encryptor }

      it "encrypts the data" do
        CryptKeeper::Provider::Encryptor.any_instance.should_receive(:encrypt).with('testing')
        subject.create!(storage: 'testing')
      end

      it "decrypts the data" do
        record = subject.create!(storage: 'testing')
        CryptKeeper::Provider::Encryptor.any_instance.should_receive(:decrypt).at_least(1).times.with('toolgnitset')
        subject.find(record.id).storage
      end

      it "returns the plaintext on decrypt" do
        record = subject.create!(storage: 'testing')
        subject.find(record.id).storage.should == 'testing'
      end

      it "does not encrypt or decrypt nil" do
        data = subject.create!(storage: nil)
        data.storage.should be_nil
      end

      it "does not encrypt or decrypt empty strings" do
        data = subject.create!(storage: "")
        data.storage.should be_empty
      end

      it "converts numbers to strings" do
        data = subject.create!(storage: 1)
        data.reload.storage.should == "1"
      end
    end

    context "Search" do
      subject { create_encrypted_model :storage, passphrase: 'tool', encryptor: :search_encryptor }

      it "searches if supported" do
        expect { subject.search_by_plaintext(:storage, 'test1') }.to_not raise_error
      end

      it "complains about bad columns" do
        expect { subject.search_by_plaintext(:what, 'test1') }.to raise_error(/what is not a crypt_keeper field/)
      end
    end

    context "Encodings" do
      subject { create_encrypted_model :storage, key: 'tool', salt: 'salt', encryptor: :aes_new, encoding: 'utf-8' }

      it "forces the encoding on decrypt" do
        record = subject.create!(storage: 'Tromsø')
        record.reload
        expect(record.storage).to eql('Tromsø')
      end

      it "converts from other encodings" do
        plaintext = "\xC2\xA92011 AACR".force_encoding('ASCII-8BIT')
        record = subject.create!(storage: plaintext)
        record.reload
        expect(record.storage.encoding.name).to eql('UTF-8')
      end
    end

    context "Initial Table Encryption" do
      subject { create_encrypted_model :storage, key: 'tool', salt: 'salt', encryptor: :aes_new }

      before do
        subject.delete_all
        c = create_model
        5.times { |i|  c.create! storage: "testing#{i}" }
      end

      it "encrypts the table" do
        expect { subject.first(5).map(&:storage) }.to raise_error(OpenSSL::Cipher::CipherError)
        subject.encrypt_table!
        expect { subject.first(5).map(&:storage) }.not_to raise_error
      end
    end

    context "Table Decryption (Reverse of Initial Table Encryption)" do
      subject { create_encrypted_model :storage, key: 'tool', salt: 'salt', encryptor: :aes_new }
      let!(:storage_entries) { 5.times.map { |i| "testing#{i}" } }

      before do
        subject.delete_all
        storage_entries.each { |entry| subject.create! storage: entry}
      end

      it "decrypts the table" do
        subject.decrypt_table!
        expect( create_model.first(5).map(&:storage) ).to eq( storage_entries )
      end
    end

    context "Missing Attributes" do
      subject { create_encrypted_model :storage, key: 'tool', salt: 'salt', encryptor: :aes_new, encoding: 'utf-8' }

      it "doesn't attempt decryption of missing attributes" do
        subject.create!(storage: 'blah')
        expect { subject.select(:id).first }.to_not raise_error
      end
    end
  end
end
