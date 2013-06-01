require 'spec_helper'

module CryptKeeper
  module Provider
    describe Aes do
      subject { Aes.new(key: 'cake') }

      describe "#initialize" do
        let(:hexed_key) do
          Digest::SHA256.digest('cake')
        end

        its(:key) { should == hexed_key }
        specify { expect { Aes.new }.to raise_error(ArgumentError, "Missing :key") }
      end

      describe "#encrypt" do
        let(:encrypted) do
          subject.encrypt 'string'
        end

        specify { encrypted.should_not == 'string' }
        specify { encrypted.should_not be_blank }

        context "blank strings" do
          let(:encrypted) do
            subject.encrypt ['', nil]
          end

          specify { encrypted.should == ['', nil] }
        end
      end

      describe "#decrypt" do
        let(:cipher_text) do
          "MC41MDk5MjI2NjgxMDI1MDI2OmNyeXB0X2tlZXBlcjpPI/8dCqWXDMVj7Jqs\nuwf/\n"
        end

        specify { subject.decrypt([cipher_text, '', nil]).should == ['string', '', nil] }
      end
    end
  end
end
