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

        context "an empty string" do
          let(:encrypted) do
            subject.encrypt ''
          end

          specify { encrypted.should == '' }
        end

        context "a nil" do
          let(:encrypted) do
            subject.encrypt nil
          end

          specify { encrypted.should be_nil }
        end
      end

      describe "#decrypt" do
        let(:decrypted) do
          subject.decrypt "MC41MDk5MjI2NjgxMDI1MDI2OmNyeXB0X2tlZXBlcjpPI/8dCqWXDMVj7Jqs\nuwf/\n"
        end

        specify { decrypted.should == 'string' }

        context "an empty string" do
          let(:decrypted) do
            subject.decrypt ''
          end

          specify { decrypted.should == '' }
        end

        context "a nil" do
          let(:decrypted) do
            subject.decrypt nil
          end

          specify { decrypted.should be_nil }
        end
      end
    end
  end
end
