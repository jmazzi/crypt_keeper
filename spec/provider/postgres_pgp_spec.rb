require 'spec_helper'

module CryptKeeper
  module Provider
    describe PostgresPgp do
      use_postgres

      let(:cipher_text) { '\\xc30d0407030283b15f71b6a7d0296cd23501bd2c8fe3c7a56005ff4619527c4291509a78c77a6758cddd2a14acbde589fa10b3e0686865182d3beadaf237b9f928e7ba1810b8' }
      let(:plain_text)  { 'test' }

      let(:integer_cipher_text) { '\xc30d040703028c65c58c0e9d015360d2320125112fc38f094e57cce1c0313f3eea4a7fc3e95c048bc319e25003ab6f29ceabe3609089d12094508c1eb79a2d70f95233' }
      let(:integer_plain_text) { 1 }

      subject { PostgresPgp.new key: 'candy' }

      its(:key) { should == 'candy' }

      context "key is a proc" do
        subject { PostgresPgp.new key: -> { 'candy' } }
        its(:key) { should == 'candy' }
      end

      describe "#initialize" do
        specify { expect { PostgresPgp.new }.to raise_error(ArgumentError, "Missing :key") }
      end

      describe "#encrypt" do
        context "Strings" do
          specify { subject.encrypt(plain_text).should_not == plain_text }
          specify { subject.encrypt(plain_text).should_not be_empty }
        end

        context "Integers" do
          specify { subject.encrypt(integer_plain_text).should_not == integer_plain_text }
          specify { subject.encrypt(integer_plain_text).should_not be_empty }
        end
      end

      describe "#decrypt" do
        specify { subject.decrypt(cipher_text).should == plain_text }
      end
    end
  end
end
