require 'spec_helper'

module CryptKeeper
  module Provider
    describe PostgresPgp do
      use_postgres

      let(:cipher_text) { '\xc30d04070302f1a092093988b26873d235017203ce086a53fce1925dc39b4e972e534f192d10b94af3dcf8589abc1f828456f5d3e20b225d56006ffd1e312e3b8a492a6010e9' }
      let(:plain_text)  { 'test' }

      let(:integer_cipher_text) { '\xc30d04070302c8d266353bcf2fc07dd23201153f9d9c32fbb3c36b9b0db137bf8b6c609172210d89ded63f11dff23d1ddbf5111c0266549dde26175c4425e06bb4bd6f' }

      let(:integer_plain_text) { 1 }

      subject { PostgresPgp.new key: ENCRYPTION_PASSWORD }

      its(:key) { should == ENCRYPTION_PASSWORD }

      describe "#initialize" do
        specify { expect { PostgresPgp.new }.to raise_error(ArgumentError, "Missing :key") }
      end

      describe "#encrypt" do
        context "Strings" do
          specify { subject.encrypt(plain_text).should_not == plain_text }
          specify { subject.encrypt(plain_text).should_not be_empty }
        end

        context "Integers" do
          specify { subject.encrypt(integer_plain_text).should_not == integer_plain_text }
          specify { subject.encrypt(integer_plain_text).should_not be_empty }
        end
      end

      describe "#decrypt" do
        specify { subject.decrypt(cipher_text).should == plain_text }
        specify { subject.decrypt(integer_cipher_text).should == integer_plain_text.to_s }
      end

      describe "#search" do
        it "finds the matching record" do
          SensitiveDataPg.create!(storage: 'blah2')
          match = SensitiveDataPg.create!(storage: 'blah')
          SensitiveDataPg.search_by_plaintext(:storage, 'blah').first.should == match
        end
      end

      describe "Custom pgcrypto options" do
        let(:pgcrypto_options) { 'compress-level=0' }

        subject { PostgresPgp.new key: 'candy', pgcrypto_options: pgcrypto_options }

        it "reads and writes" do
          queries = logged_queries do
            encrypted = subject.encrypt(plain_text)
            subject.decrypt(encrypted).should == plain_text
          end

          queries.should_not be_empty

          queries.select { |query| query.include?("pgp_sym_encrypt") }.each do |q|
            q.should include(pgcrypto_options)
          end
        end
      end
    end
  end
end
