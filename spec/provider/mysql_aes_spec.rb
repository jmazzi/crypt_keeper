require 'spec_helper'

module CryptKeeper
  module Provider
    describe MysqlAes do
      use_mysql

      let(:plain_text) { 'test' }

      # MySQL stores AES encrypted strings in binary which you can't paste
      # into a spec :). This is a Base64 encoded string of 'test' AES encrypted
      # by AES_ENCRYPT()
      let(:cipher_text) do
        "nbKOoWn8kvAw9k/C2Mex6Q==\n"
      end

      subject { MysqlAes.new key: 'candy' }

      its(:key) { should == 'candy' }

      describe "#initialize" do
        specify { expect { MysqlAes.new }.to raise_error(ArgumentError, "Missing :key") }
      end

      describe "#encrypt" do
        specify { subject.encrypt(plain_text).should_not == plain_text }
        specify { subject.encrypt(plain_text).should_not be_blank }
      end

      describe "#decrypt" do
        specify { subject.decrypt(cipher_text).should == plain_text }
      end

      describe "#search" do
        it "finds the matching record" do
          SensitiveDataMysql.create!(storage: 'blah2')
          match = SensitiveDataMysql.create!(storage: 'blah')
          SensitiveDataMysql.search_by_plaintext(:storage, 'blah').first.should == match
        end

        it "keeps the scope" do
          SensitiveDataMysql.create!(storage: 'blah')
          SensitiveDataMysql.create!(storage: 'blah')

          scope = SensitiveDataMysql.limit(1)
          expect(scope.search_by_plaintext(:storage, 'blah').count).to eql(1)
        end
      end
    end
  end
end
