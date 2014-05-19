require 'spec_helper'

module CryptKeeper
  module Provider
    describe MysqlAesNew do
      use_mysql

      let(:plain_text) { 'test' }

      # MySQL stores AES encrypted strings in binary which you can't paste
      # into a spec :). This is a Base64 encoded string of 'test' AES encrypted
      # by AES_ENCRYPT()
      let(:cipher_text) do
        "fBN8i7bx/DGAA4NJ4EWi0A=="
      end

      subject { MysqlAesNew.new key: ENCRYPTION_PASSWORD, salt: 'salt' }

      its(:key) { should == "825e8c5e8ca394818b307b22b8cb7d3df2735e9c1e5838b476e7719135a4f499f2133022c1a0e8597c9ac1507b0f0c44328a40049f9704fab3598c5dec120724" }

      describe "#initialize" do
        specify { expect { MysqlAesNew.new }.to raise_error(ArgumentError, "Missing :key") }
        specify { expect { MysqlAesNew.new(key: 'blah') }.to raise_error(ArgumentError, "Missing :salt") }
      end

      describe "#encrypt" do
        specify { subject.encrypt(plain_text).should_not == plain_text }
        specify { subject.encrypt(plain_text).should_not be_blank }
      end

      describe "#decrypt" do
        specify { subject.decrypt(cipher_text).should == plain_text }
      end

      describe "#search" do
        subject { mysql_model }

        it "finds the matching record" do
          subject.create!(storage: 'blah2')
          match = subject.create!(storage: 'blah')
          results = subject.search_by_plaintext(:storage, 'blah').first.should == match
        end

        it "keeps the scope" do
          subject.create!(storage: 'blah')
          subject.create!(storage: 'blah')

          scope = subject.limit(1)
          expect(scope.search_by_plaintext(:storage, 'blah').count).to eql(1)
        end
      end
    end
  end
end
