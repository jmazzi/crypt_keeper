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
        let(:encrypted) { subject.encrypt([plain_text, plain_text]) }

        specify { encrypted.should_not == [plain_text, plain_text] }
        specify { encrypted.all? { |v| v.present? }.should be_true }
      end

      describe "#decrypt" do
        specify { subject.decrypt([cipher_text, nil]).should == [plain_text, nil] }
        specify { subject.decrypt([]).should == [] }
      end
    end
  end
end
