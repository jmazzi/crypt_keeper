require 'spec_helper'

describe CryptKeeper::Provider::MysqlAesNew do
  use_mysql

  let(:plain_text) { 'test' }

  # MySQL stores AES encrypted strings in binary which you can't paste
  # into a spec :). This is a Base64 encoded string of 'test' AES encrypted
  # by AES_ENCRYPT():
  #
  #   SELECT TO_BASE64(AES_ENCRYPT('test', 'cd9c9275c80ccaec820f988edafd92bd0403d2055aed2b7094f569bc5314b88720c155f7f377addc35eff90c8bd11c34d5daaab5051c3435d2f5ad0c09d4b43e'));
  let(:cipher_text) do
    "qlwlvp6+otN1qnchZ48zNQ=="
  end

  subject { described_class.new key: ENCRYPTION_PASSWORD, salt: 'salt' }

  specify { expect(subject.key).to eq("cd9c9275c80ccaec820f988edafd92bd0403d2055aed2b7094f569bc5314b88720c155f7f377addc35eff90c8bd11c34d5daaab5051c3435d2f5ad0c09d4b43e") }

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
