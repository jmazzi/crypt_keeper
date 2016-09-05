require 'spec_helper'

module CryptKeeper
  module Provider
    describe PostgresRaw do
      use_postgres

      describe 'Without IV' do
        let(:cipher_text) { '\x78993a3c66d15ff843fda92766fb96bd' }
        let(:plain_text)  { 'test' }
        let(:integer_cipher_text) { '\xe4c205b8ccf0d53666f2d19341ab2e41' }
        let(:integer_plain_text) { 1 }

        subject { PostgresRaw.new key: ENCRYPTION_PASSWORD }

        its(:key) { should == ENCRYPTION_PASSWORD }

        describe "#initialize" do
          specify { expect { PostgresRaw.new }.to raise_error(ArgumentError, "Missing :key") }
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
          subject { postgres_model }

          it "finds the matching record" do
            subject.create!(storage: 'blah2')
            match = subject.create!(storage: 'blah')
            subject.search_by_plaintext(:storage, 'blah').first.should == match
          end
        end

        describe "Custom pgcrypto options" do
          let(:pgcrypto_options) { 'bf-cbc/pad:pkcs' }

          subject { PostgresRaw.new key: 'candy', pgcrypto_options: pgcrypto_options }

          it "reads and writes" do
            queries = logged_queries do
              encrypted = subject.encrypt(plain_text)
              subject.decrypt(encrypted).should == plain_text
            end

            queries.should_not be_empty

            queries.select { |query| query.include?("encrypt") || query.include?("decrypt")}.each do |q|
              q.should include(pgcrypto_options)
            end
          end
        end
      end

      describe 'With IV' do
        let(:iv) { 'anothersupermadsecretstring' }
        let(:cipher_text) { '\x7d468abaab79d8b329b49ecdb7c8a4a7' }
        let(:plain_text)  { 'test' }
        let(:integer_cipher_text) { '\xa8d80852a831597af8ae1eb5d8964175' }
        let(:integer_plain_text) { 1 }

        subject { PostgresRaw.new key: ENCRYPTION_PASSWORD, iv: iv }

        its(:key) { should == ENCRYPTION_PASSWORD }

        describe "#initialize" do
          specify { expect { PostgresRaw.new }.to raise_error(ArgumentError, "Missing :key") }
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
          subject { postgres_model }

          it "finds the matching record" do
            subject.create!(storage: 'blah2')
            match = subject.create!(storage: 'blah')
            subject.search_by_plaintext(:storage, 'blah').first.should == match
          end
        end

        describe "Custom pgcrypto options" do
          let(:pgcrypto_options) { 'bf-cbc/pad:pkcs' }

          subject { PostgresRaw.new key: 'candy', iv: iv, pgcrypto_options: pgcrypto_options }

          it "reads and writes" do
            queries = logged_queries do
              encrypted = subject.encrypt(plain_text)
              subject.decrypt(encrypted).should == plain_text
            end

            queries.should_not be_empty

            queries.select { |query| query.include?("encrypt") || query.include?("decrypt")}.each do |q|
              q.should include(pgcrypto_options)
            end
          end
        end
      end
    end
  end
end
