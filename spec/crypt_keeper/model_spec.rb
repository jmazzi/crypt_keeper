# encoding: utf-8

require 'spec_helper'

describe CryptKeeper::Model do
  use_sqlite

  subject { create_model }

  after do
    CryptKeeper.stub_encryption = false
  end

  describe "#crypt_keeper" do
    context "Fields" do
      it "enables encryption for the given fields" do
        subject.crypt_keeper :storage, :secret, encryptor: :fake_encryptor
        expect(subject.crypt_keeper_fields).to eq([:storage, :secret])
      end

      it "raises an exception for missing field" do
        msg = "Column :none does not exist"
        subject.crypt_keeper :none, encryptor: :fake_encryptor
        expect { subject.new.save }.to raise_error(ArgumentError, msg)
      end

      it "allows binary as a valid type" do
        subject.crypt_keeper :storage, encryptor: :fake_encryptor
        allow(subject.columns_hash['storage']).to receive(:type).and_return(:binary)
        expect(subject.new.save).to be_truthy
      end

      it "raises an exception for non text or binary fields" do
        msg = "Column :name must be of type 'text' or 'binary' to be used for encryption"
        subject.crypt_keeper :name, encryptor: :fake_encryptor
        expect { subject.new.save }.to raise_error(ArgumentError, msg)
      end
    end

    context "Options" do
      it "accepts the class name as a string" do
        subject.crypt_keeper :storage, :secret, key1: 1, key2: 2, encryptor: "FakeEncryptor"
        expect(subject.send(:encryptor_klass)).to eq(CryptKeeper::Provider::FakeEncryptor)
      end

      it "raises an error on missing encryptor" do
        expect { subject.crypt_keeper :storage, :secret }.
          to raise_error(ArgumentError, /You must specify a valid encryptor/)
      end

      it "raises an error on encryptor without base" do
        expect { subject.crypt_keeper :storage, encryptor: "InvalidEncryptor" }.
          to raise_error(ArgumentError, /You must specify a valid encryptor/)
      end
    end
  end

  context "Encryption and Decryption" do
    let(:plain_text) { 'plain_text' }
    let(:cipher_text) { 'tooltxet_nialp' }

    subject { create_encrypted_model :storage, passphrase: 'tool', encryptor: :encryptor }

    it "encrypts the data" do
      expect_any_instance_of(CryptKeeper::Provider::Encryptor).to receive(:encrypt).with('testing')
      subject.create!(storage: 'testing')
    end

    it "decrypts the data" do
      record = subject.create!(storage: 'testing')
      expect_any_instance_of(CryptKeeper::Provider::Encryptor).to receive(:decrypt).at_least(1).times.with('toolgnitset')
      subject.find(record.id).storage
    end

    it "returns the plaintext on decrypt" do
      record = subject.create!(storage: 'testing')
      expect(subject.find(record.id).storage).to eq('testing')
    end

    it "does not encrypt or decrypt nil" do
      data = subject.create!(storage: nil)
      expect(data.storage).to be_nil
    end

    it "does not encrypt or decrypt empty strings" do
      data = subject.create!(storage: "")
      expect(data.storage).to be_empty
    end

    it "converts numbers to strings" do
      data = subject.create!(storage: 1)
      expect(data.reload.storage).to eq("1")
    end

    it "does not decrypt when stubbing is enabled" do
      CryptKeeper.stub_encryption = true
      record = subject.create!(storage: "testing")
      expect_any_instance_of(CryptKeeper::Provider::Encryptor).to_not receive(:decrypt)
      subject.find(record.id).storage
    end

    it "does not decrypt when stubbing is enabled after model is created" do
      record = subject.create!(storage: "testing")
      CryptKeeper.stub_encryption = true
      expect_any_instance_of(CryptKeeper::Provider::Encryptor).to_not receive(:decrypt)
      subject.find(record.id).storage
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
      expect { subject.first(5).map(&:storage).map(&:to_s) }.to raise_error(OpenSSL::Cipher::CipherError)
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
