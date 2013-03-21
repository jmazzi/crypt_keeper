require 'spec_helper'

module CryptKeeper
  module Provider
    describe Aes do
      context "strict mode (default)" do
        subject { Aes.new(key: 'cake') }

        describe "#initialize" do
          let(:hexed_key) do
            Digest::SHA256.digest('cake')
          end

          its(:key) { should == hexed_key }
          its(:strict_mode) { should be_true }
          specify { expect { Aes.new }.to raise_error(ArgumentError, "Missing :key") }
        end

        describe "#encrypt" do
          let(:encrypted) do
            subject.encrypt 'string'
          end

          specify { encrypted.should_not == 'string' }
          specify { encrypted.should_not be_blank }
          specify { expect { subject.encrypt('') }.to raise_error(ArgumentError, "empty string not allowed in strict mode") }
        end

        describe "#decrypt" do
          let(:decrypted) do
            subject.decrypt "MC41MDk5MjI2NjgxMDI1MDI2OmNyeXB0X2tlZXBlcjpPI/8dCqWXDMVj7Jqs\nuwf/\n"
          end

          specify { decrypted.should == 'string' }

          specify { expect { subject.decrypt('') }.to raise_error(ArgumentError, "empty string not allowed in strict mode") }
        end

        describe "#encryptable?" do
          specify { subject.send(:encryptable?, '').should be_false }
          specify { subject.send(:encryptable?, ' ').should be_true }
        end
      end

      context "not-strict mode" do
        subject { Aes.new(key: 'cake', strict_mode: false) }

        its(:strict_mode) { should be_false }

        describe "#encrypt" do
          specify { expect { subject.encrypt('') }.not_to raise_error(ArgumentError) }
        end

        describe "#decrypt" do
          specify { expect { subject.decrypt('') }.not_to raise_error(ArgumentError) }
        end

        describe "#encryptable?" do
          specify { subject.send(:encryptable?, '').should be_true }
          specify { subject.send(:encryptable?, ' ').should be_true }
        end
      end
    end
  end
end
