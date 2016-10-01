require 'spec_helper'

module CryptKeeper
  module Provider
    describe Aes do
      subject { described_class.new(key: 'cake') }

      describe "#initialize" do
        let(:hexed_key) do
          Digest::SHA256.digest('cake')
        end

        specify { expect(subject.key).to eq(hexed_key) }
        specify { expect { described_class.new }.to raise_error(ArgumentError, "Missing :key") }
      end

      describe "#encrypt" do
        let(:encrypted) do
          subject.encrypt 'string'
        end

        specify { expect(encrypted).to_not eq('string') }
        specify { expect(encrypted).to_not be_blank }

        context "an empty string" do
          let(:encrypted) do
            subject.encrypt ''
          end

          specify { expect(encrypted).to be_blank }
        end

        context "a nil" do
          let(:encrypted) do
            subject.encrypt nil
          end

          specify { expect(encrypted).to be_nil }
        end
      end

      describe "#decrypt" do
        let(:decrypted) do
          subject.decrypt "MC41MDk5MjI2NjgxMDI1MDI2OmNyeXB0X2tlZXBlcjpPI/8dCqWXDMVj7Jqs\nuwf/\n"
        end

        specify { expect(decrypted).to eq('string') }

        context "an empty string" do
          let(:decrypted) do
            subject.decrypt ''
          end

          specify { expect(decrypted).to be_blank }
        end

        context "a nil" do
          let(:decrypted) do
            subject.decrypt nil
          end

          specify { expect(decrypted).to be_nil }
        end
      end
    end
  end
end
