require 'spec_helper'

describe CryptKeeper::Provider::PostgresPgp do
  use_postgres

  let(:cipher_text) { '\xc30d04070302f1a092093988b26873d235017203ce086a53fce1925dc39b4e972e534f192d10b94af3dcf8589abc1f828456f5d3e20b225d56006ffd1e312e3b8a492a6010e9' }
  let(:plain_text)  { 'test' }

  let(:integer_cipher_text) { '\xc30d04070302c8d266353bcf2fc07dd23201153f9d9c32fbb3c36b9b0db137bf8b6c609172210d89ded63f11dff23d1ddbf5111c0266549dde26175c4425e06bb4bd6f' }

  let(:integer_plain_text) { 1 }

  subject { described_class.new key: ENCRYPTION_PASSWORD }

  specify { expect(subject.key).to eq(ENCRYPTION_PASSWORD) }

  describe "#initialize" do
    specify { expect { described_class.new }.to raise_error(ArgumentError, "Missing :key") }
  end

  describe "#encrypt" do
    context "Strings" do
      specify { expect(subject.encrypt(plain_text)).to_not eq(plain_text) }
      specify { expect(subject.encrypt(plain_text)).to_not be_empty }
    end

    context "Integers" do
      specify { expect(subject.encrypt(integer_plain_text)).to_not eq(integer_plain_text) }
      specify { expect(subject.encrypt(integer_plain_text)).to_not be_empty }
    end

    it "filters StatementInvalid errors" do
      subject.pgcrypto_options = "invalid"

      begin
        subject.encrypt(plain_text)
      rescue ActiveRecord::StatementInvalid => e
        expect(e.message).to_not include("invalid")
        expect(e.message).to_not include(ENCRYPTION_PASSWORD)
      end
    end
  end

  describe "#decrypt" do
    specify { expect(subject.decrypt(cipher_text)).to eq(plain_text) }
    specify { expect(subject.decrypt(integer_cipher_text)).to eq(integer_plain_text.to_s) }
    specify { expect(subject.decrypt(plain_text)).to eq(plain_text) }

    it "filters StatementInvalid errors" do
      begin
        subject.decrypt("invalid")
      rescue ActiveRecord::StatementInvalid => e
        expect(e.message).to_not include("invalid")
        expect(e.message).to_not include(ENCRYPTION_PASSWORD)
      end
    end
  end

  describe "#search" do
    subject { postgres_model }

    it "finds the matching record" do
      subject.create!(storage: 'blah2')
      match = subject.create!(storage: 'blah')
      expect(subject.search_by_plaintext(:storage, 'blah').first).to eq(match)
    end
  end

  describe "Custom pgcrypto options" do
    let(:pgcrypto_options) { 'compress-level=0' }

    subject { described_class.new key: 'candy', pgcrypto_options: pgcrypto_options }

    it "reads and writes" do
      queries = logged_queries do
        encrypted = subject.encrypt(plain_text)
        expect(subject.decrypt(encrypted)).to eq(plain_text)
      end

      expect(queries).to_not be_empty

      queries.select { |query| query.include?("pgp_sym_encrypt") }.each do |q|
        expect(q).to include(pgcrypto_options)
      end
    end
  end
end
