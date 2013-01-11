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

      context "key is a proc" do
        subject { MysqlAes.new key: -> { 'candy' } }
        its(:key) { should == 'candy' }
      end

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
    end
  end
end
