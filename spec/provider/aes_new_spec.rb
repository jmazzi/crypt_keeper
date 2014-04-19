require 'spec_helper'

module CryptKeeper
  module Provider
    describe AesNew do
      subject { AesNew.new(key: 'cake', salt: 'salt') }

      describe "#initialize" do
        let(:digested_key) do
          ::Armor.digest('cake', 'salt')
        end

        its(:key) { should == digested_key }
        specify { expect { AesNew.new }.to raise_error(ArgumentError, "Missing :key") }
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
          subject.decrypt "V02ebRU2wLk25AizasROVg==$kE+IpRaUNdBfYqR+WjMqvA=="
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
