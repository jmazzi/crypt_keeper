require 'spec_helper'

describe CryptKeeper::Provider::MysqlAesNew do
  use_mysql

  let(:plain_text) { 'test' }

  # MySQL stores AES encrypted strings in binary which you can't paste
  # into a spec :). This is a Base64 encoded string of 'test' AES encrypted
  # by AES_ENCRYPT()
  let(:cipher_text) do
    "fBN8i7bx/DGAA4NJ4EWi0A=="
  end

  subject { described_class.new key: ENCRYPTION_PASSWORD, salt: 'salt' }

  specify { expect(subject.key).to eq("825e8c5e8ca394818b307b22b8cb7d3df2735e9c1e5838b476e7719135a4f499f2133022c1a0e8597c9ac1507b0f0c44328a40049f9704fab3598c5dec120724") }

  describe "#initialize" do
    specify { expect { described_class.new }.to raise_error(ArgumentError, "Missing :key") }
    specify { expect { described_class.new(key: 'blah') }.to raise_error(ArgumentError, "Missing :salt") }
  end

  describe "#encrypt" do
    specify { expect(subject.encrypt(plain_text)).to_not eq(plain_text) }
    specify { expect(subject.encrypt(plain_text)).to_not be_blank }
  end

  describe "#decrypt" do
    specify { expect(subject.decrypt(cipher_text)).to eq(plain_text) }
  end

  describe "#search" do
    subject { mysql_model }

    it "finds the matching record" do
      subject.create!(storage: 'blah2')
      match = subject.create!(storage: 'blah')
      expect(subject.search_by_plaintext(:storage, 'blah').first).to eq(match)
    end

    it "keeps the scope" do
      subject.create!(storage: 'blah')
      subject.create!(storage: 'blah')

      scope = subject.limit(1)
      expect(scope.search_by_plaintext(:storage, 'blah').count).to eq(1)
    end
  end
end
