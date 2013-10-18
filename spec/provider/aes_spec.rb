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
      end

      describe "#decrypt" do
        let(:decrypted) do
          subject.decrypt "MC41MDk5MjI2NjgxMDI1MDI2OmNyeXB0X2tlZXBlcjpPI/8dCqWXDMVj7Jqs\nuwf/\n"
        end

        specify { decrypted.should == 'string' }
      end

      describe "#search" do
        let(:records) do
          [{ name: 'Bob' }, { name: 'Tim' }]
        end

        it "finds the matching record" do
          expect(subject.search(records, :name, 'Bob')).to eql([records.first])
        end
      end
    end
  end
end
