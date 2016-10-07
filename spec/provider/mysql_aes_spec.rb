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

      subject { described_class.new key: 'candy' }

      specify { expect(subject.key).to eq('candy') }

      describe "#initialize" do
        specify { expect { described_class.new }.to raise_error(ArgumentError, "Missing :key") }
      end

      describe "#encrypt" do
        specify { expect(subject.encrypt(plain_text)).to_not eq(plain_text) }
        specify { expect(subject.encrypt(plain_text)).to_not be_blank }
      end

      describe "#decrypt" do
        specify { expect(subject.decrypt(cipher_text)).to eq(plain_text) }
      end
    end
  end
end
