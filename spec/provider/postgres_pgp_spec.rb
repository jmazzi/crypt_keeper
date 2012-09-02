require 'spec_helper'

module CryptKeeper
  module Provider
    describe PostgresPgp do
      use_postgres

      let(:cipher_text) { '\\xc30d0407030283b15f71b6a7d0296cd23501bd2c8fe3c7a56005ff4619527c4291509a78c77a6758cddd2a14acbde589fa10b3e0686865182d3beadaf237b9f928e7ba1810b8' }
      let(:plain_text) { 'test' }

      subject { PostgresPgp.new key: 'candy' }

      its(:key) { should == 'candy' }

      describe "#initialize" do
        it "should raise an exception with a missing key" do
          expect { PostgresPgp.new }.to raise_error(ArgumentError, "Missing :key")
        end
      end

      describe "#encrypt" do
        it "should encrypt the string" do
          subject.encrypt(plain_text).should_not == plain_text
          subject.encrypt(plain_text).should_not be_empty
        end
      end

      describe "#decrypt" do
        it "should decrypt the string" do
          subject.decrypt(cipher_text).should == plain_text
        end
      end
    end
  end
end
